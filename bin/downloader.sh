#!/usr/bin/env bash

# downloader.sh
#
# Download binaries from GitHub release pages or other sources and move them
# to /usr/local/bin and make them executable.

set -e
set -o pipefail

check_is_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root."
        exit
    fi
}

usage() {
    cat <<USAGE
downloader.sh
    This script downloads binaries and tools and instals them locally

Flags:
       --version string         get specified version of the binary
   -h, --help                   print this help

Tools:
    docker-compose
    docker-machine
    helm
    kind
    kops
    kubectl
    kustomize
    minikube
    packer
    rke
    skaffold
    terraform
    tilt
    vagrant
    vault
    velero
USAGE
}

latest_tag() {
    curl -s https://api.github.com/repos/"$1"/tags |
        jq -r '.[0].name' |
        head -1
}

latest_release() {
    local keyword=""
    if [[ -n "$2" ]]; then
        keyword="$2"
    fi
    curl -s https://api.github.com/repos/"$1"/releases |
        jq -r '.[] | select(.prerelease == false).tag_name' |
        grep "${keyword}" |
        head -1
}

latest_version() {
    case "$1" in
    docker-compose) latest_release "docker/compose" ;;
    docker-machine) latest_release "docker/machine" ;;
    helm) latest_release "helm/helm" ;;
    kind) latest_release "kubernetes-sigs/kind" ;;
    kops) latest_release "kubernetes/kops" ;;
    kubectl) curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt ;;
    kustomize) latest_release "kubernetes-sigs/kustomize" "kustomize" | sed 's|kustomize/||g' ;;
    minikube) latest_release "kubernetes/minikube" ;;
    packer) latest_tag "hashicorp/packer" ;;
    rke) latest_release "rancher/rke" ;;
    skaffold) latest_release "GoogleContainerTools/skaffold" ;;
    terraform) latest_tag "hashicorp/terraform" ;;
    tilt) latest_release "tilt-dev/tilt" ;;
    vagrant) latest_tag "hashicorp/vagrant" ;;
    vault) latest_tag "hashicorp/vault" ;;
    velero) latest_release "vmware-tanzu/velero" ;;
    esac
}

download() {
    # check which download command (wget or curl) is available
    local command=""
    local output=""
    local silent=""
    local redirect=""

    if command -v curl >/dev/null; then
        command="curl"
        output="-o"
        silent="-s"
        redirect="-L"
    elif command -v wget >/dev/null; then
        command="wget"
        output="-O"
        silent="-q"
        redirect=""
    else
        echo "Error: Unable to find 'wget' or 'curl'"
        exit 1
    fi

    cd /tmp

    local name=$1
    local url=$2
    local type=$3
    local target=$4

    local file=""

    if [[ "$type" == "" ]]; then
        file="$name"
    elif [[ "$type" == "tar.gz" ]]; then
        file="$name.tar.gz"
    elif [[ "$type" == "zip" ]]; then
        file="$name.zip"
    fi

    echo "Downloading ${binary}@v${version} ..."

    $command "$silent" "$redirect" "$output" "$file" "$url"

    if [[ -n "$type" ]]; then
        echo "Unpacking ${file} ..."

        if [[ "$type" == "tar.gz" ]]; then
            tar -xzf "${file}" 2>&1
        elif [[ "$type" == "zip" ]]; then
            unzip "${file}" 2>&1
        fi

        rm "${file}"
    fi

    if [[ -n "$target" ]]; then
        target=$(echo "$target" | sed 's|^/||g' | sed 's|/$||g')

        mv "$target/$name" "$name"
        rm -rf "$target"
    fi

    chmod +x "$name"

    echo "Moving $name to /usr/local/bin ..."

    mv "$name" /usr/local/bin
}

main() {
    check_is_sudo

    local binary=""
    local version="latest"

    while [ -n "$1" ]; do
        case "$1" in
        --version)
            version=$2
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            if [[ -n "$binary" ]]; then
                echo "Error: cannot download more than one binary at a time"
                exit 1
            fi
            binary=$1
            shift 1
            ;;
        esac
    done

    if [[ -z "$version" ]]; then
        usage
        exit 1
    fi

    if [[ "$version" == "latest" ]]; then
        version=$(latest_version "$binary")
    fi

    # shellcheck disable=SC2116
    version=$(echo "${version//v/}")

    if [[ -z "$binary" ]]; then
        usage
        exit 1
    fi

    local url=""
    local type=""
    local target=""

    case "$binary" in
    docker-compose)
        url="https://github.com/docker/compose/releases/download/${version}/docker-compose-linux-x86_64"
        ;;
    docker-machine)
        url="https://github.com/docker/machine/releases/download/v${version}/docker-machine-linux-x86_64"
        ;;
    helm)
        url="https://get.helm.sh/helm-v${version}-linux-amd64.tar.gz"
        type="tar.gz"
        target="linux-amd64/"
        ;;
    kind)
        url="https://github.com/kubernetes-sigs/kind/releases/download/v${version}/kind-linux-amd64"
        ;;
    kops)
        url="https://github.com/kubernetes/kops/releases/download/v${version}/kops-linux-amd64"
        ;;
    kubectl)
        url="https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/linux/amd64/kubectl"
        ;;
    kustomize)
        url="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${version}/kustomize_v${version}_linux_amd64.tar.gz"
        type="tar.gz"
        ;;
    minikube)
        url="https://storage.googleapis.com/minikube/releases/v${version}/minikube-linux-amd64"
        ;;
    packer)
        url="https://releases.hashicorp.com/packer/${version}/packer_${version}_linux_amd64.zip"
        type="zip"
        ;;
    rke)
        url="https://github.com/rancher/rke/releases/download/v${version}/rke_linux-amd64"
        ;;
    skaffold)
        url="https://storage.googleapis.com/skaffold/releases/v${version}/skaffold-linux-amd64"
        ;;
    terraform)
        url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip"
        type="zip"
        ;;
    tilt)
        url="https://github.com/tilt-dev/tilt/releases/download/v${version}/tilt.${version}.linux.x86_64.tar.gz"
        type="tar.gz"
        ;;
    vagrant)
        url="https://releases.hashicorp.com/vagrant/${version}/vagrant_${version}_linux_amd64.zip"
        type="zip"
        ;;
    vault)
        url="https://releases.hashicorp.com/vault/${version}/vault_${version}_linux_amd64.zip"
        type="zip"
        ;;
    velero)
        url="https://github.com/vmware-tanzu/velero/releases/download/v${version}/velero-v${version}-linux-amd64.tar.gz"
        type="tar.gz"
        target="velero-v${version}-linux-amd64/"
        ;;
    *)
        usage
        exit 1
        ;;
    esac

    download "$binary" "$url" "$type" "$target"
    echo "Finished"
}

main "$@"
