#!/bin/bash

# End script if there is an error
# -e Exit immediately if a command exits with a non-zero status.
# -x Print commands and their arguments as they are executed.
# set -ex # Use for debugging
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# Config
TIMEZONE=America/New_York
LOCALES=(
    "en_US.UTF-8"
    "en_CA.UTF-8"
)

APT_CMD="apt-get -qq" # -qq includes -y
APT_UPDATE="${APT_CMD} update"
APT_INSTALL="${APT_CMD} install"
APT_AUTOREMOVE="${APT_CMD} autoremove"
APT_LOG_FILE="apt-operations.log"
USR_BIN_DIR=/usr/local/bin
# -s, --silent        Silent mode
# -S, --show-error    Show error even when -s is used
# -L, --location      Follow redirects
# -f, --fail          Fail silently (no output at all) on HTTP errors
CURL_CMD="curl -sSLf"

# Utils
function getLatestRelease {
    local REPO="${1}"
    ${CURL_CMD} "https://api.github.com/repos/${REPO}/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'
}

function downloadLatestRelease {
    local REPO="${1}"
    local ASSET_NAME="${2}"
    local OUTPUT_FILE="${3}"
    local USE_RAW="${4}"
    local VERSION=$(getLatestRelease ${REPO})
    if [ "${USE_RAW}" = "raw" ]; then
        local URL="https://raw.githubusercontent.com/${REPO}/${VERSION}/${ASSET_NAME}"
    else
        local URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET_NAME}"
    fi
    echo "Downloading from repo ${REPO} version ${VERSION} to file ${OUTPUT_FILE}"
    ${CURL_CMD} "${URL}" -o "${OUTPUT_FILE}"
    chmod +x "${OUTPUT_FILE}"
}

# Update all current packages
${APT_UPDATE} && ${APT_CMD} upgrade && ${APT_AUTOREMOVE} &>> ${APT_LOG_FILE}

# Timezone
TIMEDATECTL=timedatectl
if command -v "${TIMEDATECTL}"; then
  ${TIMEDATECTL} set-timezone ${TIMEZONE}
fi

# Locales
LOCALE_GEN=locale-gen
if ! command -v "${LOCALE_GEN}"; then
  ${APT_INSTALL} locales &>> ${APT_LOG_FILE}
fi
locale-gen ${LOCALES[@]}

# Tools
${APT_INSTALL} \
    byobu \
    curl \
    git \
    htop \
    silversearcher-ag \
    tig \
    vim \
    wget \
    &>> ${APT_LOG_FILE}

# Install latest Docker version
echo "Installing Docker..."
${APT_INSTALL} \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    &>> ${APT_LOG_FILE}
${CURL_CMD} https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88 &>> ${APT_LOG_FILE}
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" \
   &>> ${APT_LOG_FILE}
${APT_UPDATE} && ${APT_INSTALL} \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin \
    &>> ${APT_LOG_FILE}

# Install Docker Compose
# https://github.com/docker/compose
DOCKER_CLI_PLUGINS_DIR="/usr/local/lib/docker/cli-plugins"
DOCKER_COMPOSE_BIN="${DOCKER_CLI_PLUGINS_DIR}/docker-compose"
DOCKER_COMPOSE_REPO="docker/compose"
DOCKER_COMPOSE_ASSET="docker-compose-linux-$(uname -m)"
if ! [ -e "${DOCKER_COMPOSE_BIN}" ]; then
    mkdir -p "${DOCKER_CLI_PLUGINS_DIR}"
    echo "Installing Docker Compose..."
    downloadLatestRelease "${DOCKER_COMPOSE_REPO}" "${DOCKER_COMPOSE_ASSET}" "${DOCKER_COMPOSE_BIN}"
    echo "Docker Compose installed."
else
    echo "Docker Compose already installed."
fi

# Install Docker Compose Switch (to ease transition from Docker Compose v1)
DOCKER_COMPOSE_SWITCH_BIN="${USR_BIN_DIR}/compose-switch"
DOCKER_COMPOSE_SWITCH_REPO="docker/compose-switch"
DOCKER_COMPOSE_SWITCH_ASSET="docker-compose-linux-amd64"
if ! [ -e ${DOCKER_COMPOSE_SWITCH_BIN} ]; then
    echo "Installing Docker Switch..."
    downloadLatestRelease "${DOCKER_COMPOSE_SWITCH_REPO}" "${DOCKER_COMPOSE_SWITCH_ASSET}" "${DOCKER_COMPOSE_SWITCH_BIN}"
    # Set Docker Compose Switch to replace Docker Compose v1
    update-alternatives --install ${USR_BIN_DIR}/docker-compose docker-compose "${DOCKER_COMPOSE_SWITCH_BIN}" 99
    echo "Docker Switch installed."
else
    echo "Docker Switch already installed."
fi

# Install NeoVim
# Adds repo for latest neovim version
add-apt-repository -y ppa:neovim-ppa/stable
${APT_UPDATE} && ${APT_INSTALL} neovim &>> ${APT_LOG_FILE}
# Set neovim as default vim
update-alternatives --set vi $(which nvim)
update-alternatives --set vim $(which nvim)

# Install SpeedTest
# https://github.com/sivel/speedtest-cli
SPEEDTEST_BIN="${USR_BIN_DIR}/speedtest-cli"
SPEEDTEST_REPO="sivel/speedtest-cli"
SPEEDTEST_ASSET="speedtest.py"
if ! [ -e ${SPEEDTEST_BIN} ]; then
    echo "Installing SpeedTest CLI..."
    downloadLatestRelease "${SPEEDTEST_REPO}" "${SPEEDTEST_ASSET}" "${SPEEDTEST_BIN}" "raw"
else
    echo "SpeedTest CLI already installed."
fi

# Make sure `python` exists
PYTHON_BIN=/usr/bin/python
if ! [ -x "$(command -v python)" ] || ! [ -e ${PYTHON_BIN} ]; then
    echo "Python is not installed, trying to symlink python3..."
    if [ -x "$(command -v python3)" ]; then
        PYTHON3_BIN=$(command -v python3)
        echo "Symlinking python3 (${PYTHON3_BIN}) to python (${PYTHON_BIN})..."
        ln -s ${PYTHON3_BIN} ${PYTHON_BIN}
    fi
fi

# Install ZSH and Prezto
# https://github.com/sorin-ionescu/prezto
echo "Installing ZSH and Prezto..."
${APT_INSTALL} zsh &>> ${APT_LOG_FILE}
ZSH_BIN=$(command -v zsh)
PREZTO_DIR="${HOME}/.zprezto"
PREZTORC_URL="https://raw.githubusercontent.com/yorch/ubuntu-server-bootstrap/main/.zpreztorc"
PREZTO_REPO_URL="https://github.com/sorin-ionescu/prezto.git"

if [ -x "${ZSH_BIN}" ]; then
    if ! [ -d "${PREZTO_DIR}" ]; then
        git clone --recursive "${PREZTO_REPO_URL}" "${PREZTO_DIR}"
        ${CURL_CMD} "${PREZTORC_URL}" -o "${PREZTO_DIR}/runcoms/zpreztorc"
        ${ZSH_BIN} -c "
            setopt EXTENDED_GLOB
            for rcfile in \"\${HOME}\"/.zprezto/runcoms/^README.md(.N); do
                echo \"\${rcfile}\"
                ln -s \"\$rcfile\" \"\${HOME}/.\${rcfile:t}\"
            done"
        chsh -s /bin/zsh
    else
        echo "Prezto already installed."
    fi
else
    echo "ERROR - Could not find ZSH even though we tried to install it"
fi

# Install or update SpaceVim
${CURL_CMD} https://spacevim.org/install.sh | bash

# Enable multiplexer `byobu`
# byobu-enable

# Cleanup old packages
${APT_AUTOREMOVE} &>> ${APT_LOG_FILE}
# Cleanup caches
${APT_CMD} clean &>> ${APT_LOG_FILE}

echo
echo "All Done! You should restart the machine now!"
echo "A log file is available at ${APT_LOG_FILE}"
echo
