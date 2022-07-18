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
)

APT_CMD="apt-get -qq" # -qq includes -y
APT_UPDATE="${APT_CMD} update"
APT_INSTALL="${APT_CMD} install"
APT_AUTOREMOVE="${APT_CMD} autoremove"
LOG_FILE="bootstrap_$(date +'%Y%m%d%H%M%S').log"
USR_BIN_DIR=/usr/local/bin
# -s, --silent        Silent mode
# -S, --show-error    Show error even when -s is used
# -L, --location      Follow redirects
# -f, --fail          Fail silently (no output at all) on HTTP errors
CURL_CMD="curl -sSLf"

# Utils
function log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $@"
}
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
    log "Downloading from repo ${REPO} version ${VERSION} to file ${OUTPUT_FILE}"
    ${CURL_CMD} "${URL}" -o "${OUTPUT_FILE}"
    chmod +x "${OUTPUT_FILE}"
}

echo
echo "-----------------------------------------------------------------------------------------------------"
log "Starting $(echo $0), this will take a few minutes depending on your system."
echo "-----------------------------------------------------------------------------------------------------"
echo

# Update all current packages
log "Upgrading existing packages..."
${APT_UPDATE} &>> ${LOG_FILE}
${APT_CMD} upgrade &>> ${LOG_FILE}
${APT_AUTOREMOVE} &>> ${LOG_FILE}

# Timezone
log "Setting timezone to ${TIMEZONE}..."
if [ -x "$(command -v timedatectl)" ]; then
  timedatectl set-timezone ${TIMEZONE} &>> ${LOG_FILE}
fi

# Locales
log "Setting locales to ${LOCALES[*]}..."
LOCALE_GEN=locale-gen
if ! [ -x "$(command -v ${LOCALE_GEN})" ]; then
  ${APT_INSTALL} locales &>> ${LOG_FILE}
fi
${LOCALE_GEN} ${LOCALES[@]} &>> ${LOG_FILE}

# Tools
log "Installing tools..."
${APT_INSTALL} \
    byobu \
    curl \
    git \
    htop \
    silversearcher-ag \
    tig \
    vim \
    wget \
    &>> ${LOG_FILE}

# Install latest Docker version
log "Installing Docker..."
${APT_INSTALL} \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    &>> ${LOG_FILE}
${CURL_CMD} https://download.docker.com/linux/ubuntu/gpg | apt-key add - &>> ${LOG_FILE}
apt-key fingerprint 0EBFCD88 &>> ${LOG_FILE}
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" \
   &>> ${LOG_FILE}
${APT_UPDATE} &>> ${LOG_FILE}
${APT_INSTALL} \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin \
    &>> ${LOG_FILE}

# Docker Compose
# https://github.com/docker/compose
DOCKER_CLI_PLUGINS_DIR="/usr/local/lib/docker/cli-plugins"
DOCKER_COMPOSE_BIN="${DOCKER_CLI_PLUGINS_DIR}/docker-compose"
DOCKER_COMPOSE_REPO="docker/compose"
DOCKER_COMPOSE_ASSET="docker-compose-linux-$(uname -m)"
if ! [ -e "${DOCKER_COMPOSE_BIN}" ]; then
    mkdir -p "${DOCKER_CLI_PLUGINS_DIR}"
    log "Installing Docker Compose..."
    downloadLatestRelease "${DOCKER_COMPOSE_REPO}" "${DOCKER_COMPOSE_ASSET}" "${DOCKER_COMPOSE_BIN}"
else
    log "Docker Compose already installed."
fi

# Docker Compose Switch (to ease transition from Docker Compose v1)
DOCKER_COMPOSE_SWITCH_BIN="${USR_BIN_DIR}/compose-switch"
DOCKER_COMPOSE_SWITCH_REPO="docker/compose-switch"
DOCKER_COMPOSE_SWITCH_ASSET="docker-compose-linux-amd64"
if ! [ -e ${DOCKER_COMPOSE_SWITCH_BIN} ]; then
    log "Installing Docker Switch..."
    downloadLatestRelease "${DOCKER_COMPOSE_SWITCH_REPO}" "${DOCKER_COMPOSE_SWITCH_ASSET}" "${DOCKER_COMPOSE_SWITCH_BIN}"
    # Set Docker Compose Switch to replace Docker Compose v1
    update-alternatives --install ${USR_BIN_DIR}/docker-compose docker-compose "${DOCKER_COMPOSE_SWITCH_BIN}" 99 &>> ${LOG_FILE}
else
    log "Docker Switch already installed."
fi

# NeoVim
log "Installing NeoVim..."
# Adds repo for latest neovim version
add-apt-repository -y ppa:neovim-ppa/stable &>> ${LOG_FILE}
${APT_UPDATE} &>> ${LOG_FILE}
${APT_INSTALL} neovim &>> ${LOG_FILE}
# Set neovim as default vim
update-alternatives --set vi $(which nvim) &>> ${LOG_FILE}
update-alternatives --set vim $(which nvim) &>> ${LOG_FILE}

# SpeedTest
# https://github.com/sivel/speedtest-cli
SPEEDTEST_BIN="${USR_BIN_DIR}/speedtest-cli"
SPEEDTEST_REPO="sivel/speedtest-cli"
SPEEDTEST_ASSET="speedtest.py"
if ! [ -e ${SPEEDTEST_BIN} ]; then
    log "Installing SpeedTest CLI..."
    downloadLatestRelease "${SPEEDTEST_REPO}" "${SPEEDTEST_ASSET}" "${SPEEDTEST_BIN}" "raw"
else
    log "SpeedTest CLI already installed."
fi

# Make sure `python` exists
log "Making sure `python` exists..."
PYTHON_BIN=/usr/bin/python
if ! [ -x "$(command -v python)" ] || ! [ -e ${PYTHON_BIN} ]; then
    log "Python is not installed, trying to symlink python3..."
    if [ -x "$(command -v python3)" ]; then
        PYTHON3_BIN=$(command -v python3)
        log "Symlinking python3 (${PYTHON3_BIN}) to python (${PYTHON_BIN})..."
        ln -s ${PYTHON3_BIN} ${PYTHON_BIN}
    fi
fi

# ZSH and Prezto
# https://github.com/sorin-ionescu/prezto
log "Installing ZSH and Prezto..."
${APT_INSTALL} zsh &>> ${LOG_FILE}
ZSH_BIN=$(command -v zsh)
PREZTO_DIR="${HOME}/.zprezto"
PREZTORC_URL="https://raw.githubusercontent.com/yorch/ubuntu-server-bootstrap/main/.zpreztorc"
PREZTO_REPO_URL="https://github.com/sorin-ionescu/prezto.git"

if [ -x "${ZSH_BIN}" ]; then
    if ! [ -d "${PREZTO_DIR}" ]; then
        git clone --recursive "${PREZTO_REPO_URL}" "${PREZTO_DIR}" &>> ${LOG_FILE}
        ${CURL_CMD} "${PREZTORC_URL}" -o "${PREZTO_DIR}/runcoms/zpreztorc"
        ${ZSH_BIN} -c "
            setopt EXTENDED_GLOB
            for rcfile in \"\${HOME}\"/.zprezto/runcoms/^README.md(.N); do
                ln -s \"\$rcfile\" \"\${HOME}/.\${rcfile:t}\"
            done"
        chsh -s /bin/zsh
    else
        log "Prezto already installed."
    fi
else
    log "ERROR - Could not find ZSH even though we tried to install it"
fi

# SpaceVim
log "Installing or updating SpaceVim..."
${APT_INSTALL} fontconfig &>> ${LOG_FILE}
${CURL_CMD} https://spacevim.org/install.sh | bash

# Enable multiplexer `byobu`
# byobu-enable

# Cleanup old packages
log "Cleaning up old packages..."
${APT_AUTOREMOVE} &>> ${LOG_FILE}

# Cleanup caches
log "Cleanup caches..."
${APT_CMD} clean &>> ${LOG_FILE}

echo
log "All Done! You should restart the machine now!"
log "A log file is available at ${LOG_FILE}"
echo ""
