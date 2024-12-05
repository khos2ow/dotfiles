#!/usr/bin/env bash

# downloader.sh
#
# Download binaries from GitHub release pages or other sources
# and install them to a "bin" folder and make them executable.
#
# Modified of: https://github.com/starship/starship/blob/master/install/install.sh
#
set -e
set -o pipefail

BOLD="$(tput bold 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
WHITE="$(tput setaf 7 2>/dev/null || echo '')"
NO_COLOR="$(tput sgr0 2>/dev/null || echo '')"

BINARIES=$(
    cat <<EOF
[{
  "name": "clusterctl",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "kubernetes-sigs/cluster-api",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/kubernetes-sigs/cluster-api/releases/download/v<VERSION>/clusterctl-linux-amd64"
},
{
  "name": "docker-compose",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "docker/compose",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/docker/compose/releases/download/<VERSION>/docker-compose-linux-x86_64"
},
{
  "name": "docker-machine",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "docker/machine",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/docker/machine/releases/download/v<VERSION>/docker-machine-linux-x86_64"
},
{
  "name": "goreleaser",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "goreleaser/goreleaser",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/goreleaser/goreleaser/releases/download/v<VERSION>/goreleaser_Linux_x86_64.tar.gz"
},
{
  "name": "gomplate",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "hairyhenderson/gomplate",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/hairyhenderson/gomplate/releases/download/v<VERSION>/gomplate_linux-amd64"
},
{
  "name": "helm",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "helm/helm",
  "target": "linux-amd64/",
  "type": "tar.gz",
  "version_cmd": "version --short",
  "url": "https://get.helm.sh/helm-v<VERSION>-linux-amd64.tar.gz"
},
{
  "name": "hugo",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "gohugoio/hugo",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/gohugoio/hugo/releases/download/v<VERSION>/hugo_extended_<VERSION>_Linux-64bit.tar.gz"
},
{
  "name": "k9s",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "derailed/k9s",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "version --short",
  "url": "https://github.com/derailed/k9s/releases/download/v<VERSION>/k9s_Linux_x86_64.tar.gz"
},
{
  "name": "kind",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "kubernetes-sigs/kind",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/kubernetes-sigs/kind/releases/download/v<VERSION>/kind-linux-amd64"
},
{
  "name": "kops",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "kubernetes/kops",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/kubernetes/kops/releases/download/v<VERSION>/kops-linux-amd64"
},
{
  "name": "kompose",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "kubernetes/kompose",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/kubernetes/kompose/releases/download/v<VERSION>/kompose-linux-amd64"
},
{
  "name": "kubebuilder",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "kubernetes-sigs/kubebuilder",
  "target": "kubebuilder_<VERSION>_linux_amd64/bin/",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/kubernetes-sigs/kubebuilder/releases/download/v<VERSION>/kubebuilder_<VERSION>_linux_amd64.tar.gz"
},
{
  "name": "kubectl",
  "latest": {
    "type": "URL",
    "url": "https://storage.googleapis.com/kubernetes-release/release/stable.txt"
  },
  "repo": "",
  "target": "",
  "type": "",
  "version_cmd": "version --short --client",
  "url": "https://storage.googleapis.com/kubernetes-release/release/v<VERSION>/bin/linux/amd64/kubectl"
},
{
  "name": "kubectl-crossplane",
  "latest": {
    "type": "URL",
    "url": "https://releases.crossplane.io/stable/current/version"
  },
  "repo": "",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://releases.crossplane.io/stable/current/bin/linux_amd64/crank"
},
{
  "name": "kubie",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "sbstp/kubie",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/sbstp/kubie/releases/download/v<VERSION>/kubie-linux-amd64"
},
{
  "name": "kustomize",
  "latest": {
    "keyword": "kustomize/",
    "command": "sed 's|kustomize/||g'",
    "type": "Command",
    "url": ""
  },
  "repo": "kubernetes-sigs/kustomize",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "version --short",
  "url": "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v<VERSION>/kustomize_v<VERSION>_linux_amd64.tar.gz"
},
{
  "name": "minikube",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "kubernetes/minikube",
  "target": "",
  "type": "",
  "version_cmd": "version --short",
  "url": "https://storage.googleapis.com/minikube/releases/v<VERSION>/minikube-linux-amd64"
},
{
  "name": "packer",
  "latest": {
    "type": "Tag",
    "url": ""
  },
  "repo": "hashicorp/packer",
  "target": "",
  "type": "zip",
  "version_cmd": "",
  "url": "https://releases.hashicorp.com/packer/<VERSION>/packer_<VERSION>_linux_amd64.zip"
},
{
  "name": "rke",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "rancher/rke",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://github.com/rancher/rke/releases/download/v<VERSION>/rke_linux-amd64"
},
{
  "name": "skaffold",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "GoogleContainerTools/skaffold",
  "target": "",
  "type": "",
  "version_cmd": "",
  "url": "https://storage.googleapis.com/skaffold/releases/v<VERSION>/skaffold-linux-amd64"
},
{
  "name": "spotifyd",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "Spotifyd/spotifyd",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/Spotifyd/spotifyd/releases/download/v<VERSION>/spotifyd-linux-full.tar.gz"
},
{
  "name": "spt",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "Rigellute/spotify-tui",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/Rigellute/spotify-tui/releases/download/v<VERSION>/spotify-tui-linux.tar.gz"
},
{
  "name": "starship",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "starship/starship",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/starship/starship/releases/download/v<VERSION>/starship-x86_64-unknown-linux-gnu.tar.gz"
},
{
  "name": "terraform",
  "latest": {
    "type": "Tag",
    "url": ""
  },
  "repo": "hashicorp/terraform",
  "target": "",
  "type": "zip",
  "version_cmd": "",
  "url": "https://releases.hashicorp.com/terraform/<VERSION>/terraform_<VERSION>_linux_amd64.zip"
},
{
  "name": "terraform-docs",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "terraform-docs/terraform-docs",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/terraform-docs/terraform-docs/releases/download/v<VERSION>/terraform-docs-v<VERSION>-linux-amd64.tar.gz"
},
{
  "name": "tilt",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "tilt-dev/tilt",
  "target": "",
  "type": "tar.gz",
  "version_cmd": "",
  "url": "https://github.com/tilt-dev/tilt/releases/download/v<VERSION>/tilt.<VERSION>.linux.x86_64.tar.gz"
},
{
  "name": "vagrant",
  "latest": {
    "type": "Tag",
    "url": ""
  },
  "repo": "hashicorp/vagrant",
  "target": "",
  "type": "zip",
  "version_cmd": "--version",
  "url": "https://releases.hashicorp.com/vagrant/<VERSION>/vagrant_<VERSION>_linux_amd64.zip"
},
{
  "name": "vault",
  "latest": {
    "type": "Tag",
    "url": ""
  },
  "repo": "hashicorp/vault",
  "target": "",
  "type": "zip",
  "version_cmd": "",
  "url": "https://releases.hashicorp.com/vault/<VERSION>/vault_<VERSION>_linux_amd64.zip"
},
{
  "name": "velero",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "vmware-tanzu/velero",
  "target": "velero-v<VERSION>-linux-amd64/",
  "type": "tar.gz",
  "version_cmd": "version --client-only",
  "url": "https://github.com/vmware-tanzu/velero/releases/download/v<VERSION>/velero-v<VERSION>-linux-amd64.tar.gz"
},
{
  "name": "yq",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "mikefarah/yq",
  "target": "",
  "type": "",
  "version_cmd": "version --client-only",
  "url": "https://github.com/mikefarah/yq/releases/download/v<VERSION>/yq_linux_amd64"
}]
EOF
)

info() {
    printf "%s\n" "${BOLD}${WHITE}>${NO_COLOR} $*"
}

warn() {
    printf "%s\n" "${YELLOW}! $*${NO_COLOR}"
}

error() {
    printf "%s\n" "${RED}x $*${NO_COLOR}" >&2
}

complete() {
    printf "%s\n" "${GREEN}✓${NO_COLOR} $*"
}

# Gets path to a temporary file, even if
get_tmpfile() {
    local suffix
    suffix="$1"
    if hash mktemp; then
        printf "%s" "$(mktemp --suffix=".${suffix}")"
    else
        # No really good options here--let's pick a default + hope
        printf "/tmp/downloader%s" "${suffix}"
    fi
}

installed_version() {
    local version_cmd=""
    version_cmd="$(echo "$BINARY" | jq -r '.version_cmd')"

    if [ -n "$version_cmd" ] && [ "$version_cmd" != "null" ]; then
        eval "$NAME" "$version_cmd"
    elif "$NAME" --version >/dev/null 2>&1; then
        "$NAME" --version
    elif "$NAME" version >/dev/null 2>&1; then
        "$NAME" version
    else
        echo "unknown"
    fi
}

latest_version() {
    local type=""
    local repo=""
    local url=""
    type="$(echo "$BINARY" | jq -r '.latest.type')"
    repo="$(echo "$BINARY" | jq -r '.repo')"
    url="$(echo "$BINARY" | jq -r '.latest.url')"

    case "$type" in
    Command)
    	keyword="$(echo "$BINARY" | jq -r '.latest.keyword')"
    	commands="$(echo "$BINARY" | jq -r '.latest.command')"

        fetch "https://api.github.com/repos/${repo}/releases" |
            jq -r '.[] | select(.prerelease == false).tag_name' |
            grep "${keyword}" |
            head -1 |
			sed "s|${keyword}||g"
        ;;
    Release)
        fetch "https://api.github.com/repos/${repo}/releases" |
            jq -r '.[] | select(.prerelease == false).tag_name' |
            sort -V -r |
            head -1
        ;;
    Tag)
        fetch "https://api.github.com/repos/${repo}/tags" |
            jq -r '.[0].name' |
            head -1
        ;;
    URL)
        fetch "${url}"
        ;;
    esac
}

confirm() {
    if [ -z "${FORCE-}" ]; then
        printf "%b " "$* ${BOLD}[y/N]${NO_COLOR}"
        set +e
        read -r yn </dev/tty
        rc=$?
        set -e
        if [ $rc -ne 0 ]; then
            error "Error reading from prompt (please re-run with the '--yes' option)"
            exit 1
        fi
        if [ "$yn" != "y" ] && [ "$yn" != "yes" ]; then
            error "Aborting (please answer 'yes' to continue)"
            exit 1

        fi
    fi
}

check_bin_dir() {
    local bin_dir="$1"

    if [ ! -d "$BIN_DIR" ]; then
        error "Installation location $BIN_DIR does not appear to be a directory"
        info "Make sure the location exists and is a directory, then try again."
        exit 1
    fi

    # https://stackoverflow.com/a/11655875
    local good
    good=$(
        IFS=:
        for path in $PATH; do
            if [ "${path}" = "${bin_dir}" ]; then
                echo 1
                break
            fi
        done
    )

    if [ "${good}" != "1" ]; then
        warn "Bin directory ${bin_dir} is not in your \$PATH"
    fi
}

# Test if a location is writeable by trying to write to it. Windows does not let
# you test writeability other than by writing: https://stackoverflow.com/q/1999988
test_writeable() {
    local path="${1:-}/test.txt"

    if touch "${path}" 2>/dev/null; then
        rm "${path}"
        return 0
    else
        return 1
    fi
}

fetch() {
    local command

    if hash curl 2>/dev/null; then
        set +e
        command="curl --silent --fail --location $1"
        curl --silent --fail --location "$1"
        rc=$?
        set -e
    else
        if hash wget 2>/dev/null; then
            set +e
            command="wget -O- -q $1"
            wget -O- -q "$1"
            rc=$?
            set -e
        else
            error "No HTTP download program (curl, wget) found…"
            exit 1
        fi
    fi

    if [ $rc -ne 0 ]; then
        printf "\n" >&2
        error "Command failed (exit code $rc): ${BLUE}${command}${NO_COLOR}"
        exit $rc
    fi
}

fetch_and_unpack() {
    local sudo="$1"
    local tmpfile=""

    case "${TYPE}" in
    "")
        fetch "${URL}" >"/tmp/${NAME}"
        ;;
    tar.gz | tar.xz | zip)
        tmpfile="$(get_tmpfile "${TYPE}")"
        fetch "${URL}" >"${tmpfile}"
        if [ "${TYPE}" = "tar.gz" ]; then
            tar -xzf "${tmpfile}" -C /tmp 2>&1
        elif [ "${TYPE}" = "tar.xz" ]; then
            tar -xJf "${tmpfile}" -C /tmp 2>&1
        elif [ "${TYPE}" = "zip" ]; then
            unzip "${tmpfile}" -d /tmp 2>&1
        fi
        rm -f "${tmpfile}"
        ;;
    *)
        error "Unknown package extension."
        exit 1
        ;;
    esac

    if [ -n "${TARGET}" ]; then
        TARGET=$(echo "$TARGET" | cut -d/ -f1)

        local targetfile=""
        targetfile=$(echo "$TARGET" | cut -d/ -f2)

        if [ -z "$targetfile" ]; then
          targetfile="$NAME"
        fi

        mv "/tmp/${TARGET}/${targetfile}" "/tmp/${NAME}"
        rm -rf "/tmp/${TARGET}"
    fi

    chmod +x "/tmp/${NAME}"

    if [ "$OVERRIDE" = "true" ]; then
        ${sudo} mv "/tmp/${NAME}" "${BIN_DIR}"
    else
        ${sudo} mv "/tmp/${NAME}" "${BIN_DIR}"/"${NAME}"-"${VERSION}"
    fi
}

elevate_priv() {
    if ! hash sudo 2>/dev/null; then
        error 'Could not find the command "sudo", needed to get permissions for install.'
        info "If you are on Windows, please run your shell as an administrator, then"
        info "rerun this script. Otherwise, please run this script as root, or install"
        info "sudo."
        exit 1
    fi
    if ! sudo -v; then
        error "Superuser not granted, aborting installation"
        exit 1
    fi
}

install() {
    local msg
    local sudo

    if test_writeable "${BIN_DIR}"; then
        sudo=""
        msg="Installing $NAME, please wait…"
    else
        warn "Escalated permission are required to install to ${BIN_DIR}"
        elevate_priv
        sudo="sudo"
        msg="Installing $NAME as root, please wait…"
    fi

    info "$msg"
    fetch_and_unpack "${sudo}"
}

list_tools() {
    if [ "$SHORT" == "true" ]; then
	echo "${BINARIES}" | jq -r '. |= sort_by(.name) | .[].name'
	return
    fi

    printf "Following tools and binaries are supported:\n\n"

    local max_length=0
    while read -r object; do
        if [[ ${#object} -gt $max_length ]]; then
            max_length=${#object}
        fi
    done < <(echo "${BINARIES}" | jq -r '. |= sort_by(.name) | .[].name')

    # shellcheck disable=SC2183
    dash_line=$(printf "%*s" "$max_length")
    dash_line=${dash_line// /-}

    # shellcheck disable=SC2183
    empty_line=$(printf '%*s' "$max_length")

    printf "┌---┬-%s-┐\n"  "${dash_line}"

    local last_char=""
    while read -r object; do
        this_char=$(echo "${object}" | head -c 1 | tr '[:lower:]' '[:upper:]')
        if [[ "${this_char}" == "${last_char}" ]]; then
            printf "|   |"
        else
            if [[ "${last_char}" != "" ]]; then
                printf "├---┼-%s-┤\n" "${dash_line}"
            fi
            printf "| %s |" "${this_char}"
            last_char="${this_char}"
        fi
        printf " %s %s|\n" "${object}" "${empty_line:${#object}}"
    done < <(echo "${BINARIES}" | jq -r '. |= sort_by(.name) | .[].name')

    printf "└---┴-%s-┘\n"  "${dash_line}"
}

usage() {
    cat <<USAGE
This script downloads binaries and tools and installs them locally

Usage:
  downloader.sh [command] [BINARY] [flags]

Avialable Commands:
  check  check the latest available version
  get    get the binary at specified version
  list   show supported tools and binaries

Flags:
  -b, --bin-dir string     path to bin directory (default: /usr/loca/bin)
  -h, --help               print this help
  -o, --override boolean   override installed binary with new version (default: true)
      --short boolean      show short list (default: false)
  -v, --version string     specific binary version to download
  -y, --yes boolean        answer yes to the questions (default: false)
USAGE
}

BIN_DIR="/usr/local/bin"
COMMAND=""
BINARY=""
VERSION="latest"
OVERRIDE="true"
SHORT="false"
FORCE=

while [ "$#" -gt 0 ]; do
    case "$1" in
    check)
        if [[ -n "$COMMAND" ]]; then
            error "Cannot use commands together"
            exit 1
        fi
        COMMAND=$1
        shift 1
        ;;
    get)
        if [[ -n "$COMMAND" ]]; then
            error "Cannot use commands together"
            exit 1
        fi
        COMMAND=$1
        shift 1
        ;;
    list)
        if [[ -n "$COMMAND" ]]; then
            error "Cannot use commands together"
            exit 1
        fi
        COMMAND=$1
        shift 1
        ;;
    -b | --bin-dir)
        BIN_DIR=$2
        shift 2
        ;;
    --bin-dir=*)
        BIN_DIR="${1#*=}"
        shift 1
        ;;
    -o | --override)
        OVERRIDE=$2
        shift 2
        ;;
    --override=*)
        OVERRIDE="${1#*=}"
        shift 1
        ;;
    --short)
        SHORT=$2
        shift 2
        ;;
    --short=*)
        SHORT="${1#*=}"
        shift 1
        ;;
    -v | --version)
        VERSION=$2
        shift 2
        ;;
    --version=*)
        VERSION="${1#*=}"
        shift 1
        ;;
    -y | --yes)
        FORCE=1
        shift 1
        ;;
    --yes=*)
        FORCE="${1#*=}"
        shift 1
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        if [[ -n "$BINARY" ]]; then
            error "Cannot download more than one binary at a time"
            exit 1
        fi
        BINARY="$(echo "$BINARIES" | jq -r '.[] | select(.name == "'"$1"'")')"
        if [[ -z "$BINARY" ]]; then
            error "Unknown or unsupported binary: $1"
            exit 1
        fi
        shift 1
        ;;
    esac
done

if [[ -z "$COMMAND" ]]; then
    usage
    exit 1
fi

# 'list' command
if [[ "$COMMAND" == "list" ]]; then
    list_tools
    exit
fi

if [[ -z "$BINARY" ]]; then
    error "Binary is missing. e.g. downloader.sh $COMMAND <BINARY>"
    exit 1
fi

if [[ -z "$VERSION" ]]; then
    error "Version is missing. e.g. downloader.sh $COMMAND <BINARY> --version <VERSION>"
    exit 1
fi

NAME="$(echo "$BINARY" | jq -r '.name')"
URL="$(echo "$BINARY" | jq -r '.url')"
TYPE="$(echo "$BINARY" | jq -r '.type')"
TARGET="$(echo "$BINARY" | jq -r '.target')"

# 'check' command
if [[ "$COMMAND" == "check" ]]; then
    info "Checking latest version of $NAME"
    echo "  Installed: ${BOLD}${WHITE}$(installed_version)${NO_COLOR}"
    echo "  Available: ${BOLD}${WHITE}$(latest_version)${NO_COLOR}"

fi

# 'get' command
if [[ "$COMMAND" == "get" ]]; then
    if [[ "$VERSION" == "latest" ]]; then
        VERSION=$(latest_version)
    fi

    VERSION="${VERSION//v/}"
    URL="${URL//<VERSION>/${VERSION}}"
    TARGET="${TARGET//<VERSION>/${VERSION}}"

    printf "%b\n" "$(
        cat <<MSG
Install ${BOLD}${WHITE}${NAME} @ v${VERSION}${NO_COLOR}
   from ${BOLD}${WHITE}${URL}${NO_COLOR}
     to ${BOLD}${WHITE}${BIN_DIR}${NO_COLOR}
MSG
    )"

    confirm "Are you sure?"

    check_bin_dir "${BIN_DIR}"
    install
    complete "$NAME installed"
fi
