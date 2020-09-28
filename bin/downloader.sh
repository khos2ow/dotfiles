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
  "name": "docker-compose",
  "latest": {
    "type": "Release",
    "url": ""
  },
  "repo": "docker/compose",
  "target": "",
  "type": "",
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
  "url": "https://github.com/docker/machine/releases/download/v<VERSION>/docker-machine-linux-x86_64"
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
  "url": "https://get.helm.sh/helm-v<VERSION>-linux-amd64.tar.gz"
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
  "url": "https://github.com/kubernetes/kops/releases/download/v<VERSION>/kops-linux-amd64"
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
  "url": "https://storage.googleapis.com/kubernetes-release/release/v<VERSION>/bin/linux/amd64/kubectl"
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
  "url": "https://github.com/sbstp/kubie/releases/download/v<VERSION>/kubie-linux-amd64"
},
{
  "name": "kustomize",
  "latest": {
    "command": "latest_release \"kubernetes-sigs/kustomize\" \"kustomize\" | sed 's|kustomize/||g'",
    "type": "Command",
    "url": "TODO"
  },
  "repo": "",
  "target": "",
  "type": "tar.gz",
  "url": "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v<VERSION>/kustomize_<VERSION>_linux_amd64.tar.gz"
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
  "url": "https://storage.googleapis.com/skaffold/releases/v<VERSION>/skaffold-linux-amd64"
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
  "type": "",
  "url": "https://github.com/terraform-docs/terraform-docs/releases/download/v<VERSION>/terraform-docs-v<VERSION>-linux-amd64"
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
  "type": "tar.gz",
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
  "type": "tar.gz",
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
  "url": "https://github.com/vmware-tanzu/velero/releases/download/v<VERSION>/velero-v<VERSION>-linux-amd64.tar.gz"
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

latest_version() {
    local type=""
    local repo=""
    local url=""
    type="$(echo "$BINARY" | jq -r '.latest.type')"
    repo="$(echo "$BINARY" | jq -r '.repo')"
    url="$(echo "$BINARY" | jq -r '.latest.url')"

    case "$type" in
    Command)
        # TODO
        # fetch "https://api.github.com/repos/${repo}/releases" |
        #     jq -r '.[] | select(.prerelease == false).tag_name' |
        #     grep "${keyword}" |
        #     head -1
        ;;
    Release)
        fetch "https://api.github.com/repos/${repo}/releases" |
            jq -r '.[] | select(.prerelease == false).tag_name' |
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
    tar.gz | zip)
        tmpfile="$(get_tmpfile "${TYPE}")"
        fetch "${URL}" >"${tmpfile}"
        if [ "${TYPE}" = "tar.gz" ]; then
            tar -xzf "${tmpfile}" -C /tmp 2>&1
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
        TARGET="${TARGET//\//}"

        mv "/tmp/${TARGET}/${NAME}" "/tmp/${NAME}"
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
    cat <<LIST
Following tools and binaries are supported:

┌---┬----------------┐
| D | docker-compose |
|   | docker-machine |
├---┼----------------┤
| H | helm           |
├---┼----------------┤
| K | kind           |
|   | kops           |
|   | kubectl        |
|   | kubie          |
|   | kustomize      |
├---┼----------------┤
| M | minikube       |
├---┼----------------┤
| P | packer         |
├---┼----------------┤
| R | rke            |
├---┼----------------┤
| S | skaffold       |
├---┼----------------┤
| T | terraform      |
|   | terraform-docs |
|   | tilt           |
├---┼----------------┤
| V | vagrant        |
|   | vault          |
|   | velero         |
└---┴----------------┘
LIST
    # ┌---┬----------------------------------┐
    # | D | docker-compose    docker-machine |
    # ├---┼----------------------------------┤
    # | H | helm                             |
    # ├---┼----------------------------------┤
    # | K | kind              kops           |
    # |   | kubectl           kubie          |
    # |   | kustomize                        |
    # ├---┼----------------------------------┤
    # | M | minikube                         |
    # ├---┼----------------------------------┤
    # | P | packer                           |
    # ├---┼----------------------------------┤
    # | R | rke                              |
    # ├---┼----------------------------------┤
    # | S | skaffold                         |
    # ├---┼----------------------------------┤
    # | T | terraform         terraform-docs |
    # |   | tilt                             |
    # ├---┼----------------------------------┤
    # | V | vagrant           vault          |
    # |   | velero                           |
    # └---┴----------------------------------┘
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
  -v, --version string     specific binary version to download
  -y, --yes boolean        answer yes to the questions (default: false)
USAGE
}

BIN_DIR="/usr/local/bin"
COMMAND=""
BINARY=""
VERSION="latest"
OVERRIDE="true"
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
    latest_version
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
Install ${BOLD}${WHITE}${NAME} @ ${VERSION}${NO_COLOR}
   from ${BOLD}${WHITE}${URL}${NO_COLOR}
     to ${BOLD}${WHITE}${BIN_DIR}${NO_COLOR}
MSG
    )"

    confirm "Are you sure?"

    check_bin_dir "${BIN_DIR}"
    install
    complete "$NAME installed"
fi
