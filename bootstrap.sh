#!/bin/bash

# End script if there is an error
# -e Exit immediately if a command exits with a non-zero status.
# -x Print commands and their arguments as they are executed.
# set -eEx # Use for debugging
set -eE # same as: `set -o errexit -o errtrace` (from: https://stackoverflow.com/a/35800451)

LOG_FILE="bootstrap_$(date +'%Y%m%d%H%M%S').log"

# keep track of the last executed command
trap 'last_command=${current_command}; current_command=${BASH_COMMAND}' DEBUG
# Show an error message before exiting on error
trap 'catch ${?} ${LINENO} ${last_command} ${LOG_FILE}' ERR
# Show an error message when the script is interrupted
trap 'interrupted' SIGINT

# Config
TIMEZONE=America/New_York
LOCALES=(
    "en_US.UTF-8"
)

# APT_CMD="apt-get -qq" # -qq includes -y
APT_CMD="apt-get -y" # -qq includes -y
APT_INSTALL="${APT_CMD} install"

USR_BIN_DIR=/usr/local/bin
# -s, --silent        Silent mode
# -S, --show-error    Show error even when -s is used
# -L, --location      Follow redirects
# -f, --fail          Fail silently (no output at all) on HTTP errors
CURL_CMD="curl -sSLf"

###############################################################################
# Utils
###############################################################################
function currentDate() {
    echo "$(date +'%Y-%m-%d %H:%M:%S')"
}
function log() {
    echo "$(currentDate) - ${@}"
}
function logError() {
    local MESSAGE="${@}"
    printf "\e[31mERROR - %s\e[m\n" "${MESSAGE}"
}
function catch() {
    local ERROR_CODE="${1}"
    local LINE_NUMBER="${2}"
    local LAST_CMD="${3}"
    local LOG_FILE="${4}"
    echo
    # echo "Error ${ERROR_CODE} occurred on line ${LINE_NUMBER}"
    logError "\"${last_command}\" command failed with exit code ${ERROR_CODE} on line ${LINE_NUMBER}."
    logError "See log file ${LOG_FILE} for more information."
    echo
}
function interrupted() {
    echo "The script was interrupted, exiting"
}
function runCmdAndLog() {
    local CMD="${@}"
    echo "" &>> ${LOG_FILE}
    echo "================================================================================" &>> ${LOG_FILE}
    echo "$(currentDate) - Running command: ${CMD}" &>> ${LOG_FILE}
    echo "================================================================================" &>> ${LOG_FILE}
    eval "${CMD}" &>> ${LOG_FILE}
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

###############################################################################
# Script
###############################################################################

echo
echo "-----------------------------------------------------------------------------------------------------"
log "Starting $(echo ${0}), this will take a few minutes depending on your system."
echo "-----------------------------------------------------------------------------------------------------"
echo

# Update all current packages
log "Upgrading existing packages..."
runCmdAndLog ${APT_CMD} update
runCmdAndLog ${APT_CMD} upgrade
runCmdAndLog ${APT_CMD} autoremove

# Timezone
log "Setting timezone to ${TIMEZONE}..."
if [ -x "$(command -v timedatectl)" ]; then
  runCmdAndLog timedatectl set-timezone ${TIMEZONE}
fi

# Locales
log "Setting locales to ${LOCALES[*]}..."
LOCALE_GEN=locale-gen
if ! [ -x "$(command -v ${LOCALE_GEN})" ]; then
  runCmdAndLog ${APT_INSTALL} locales
fi
runCmdAndLog ${LOCALE_GEN} ${LOCALES[@]}

# Tools
log "Installing tools..."
runCmdAndLog ${APT_INSTALL} \
    byobu \
    curl \
    git \
    htop \
    silversearcher-ag \
    software-properties-common \
    tig \
    vim \
    wget

# Install latest Docker version
if ! [ -e "$(command -v docker)" ]; then
    log "Installing Docker..."
    runCmdAndLog ${APT_INSTALL} \
        ca-certificates \
        gnupg \
        lsb-release
    runCmdAndLog mkdir -p /etc/apt/keyrings
    runCmdAndLog "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
    runCmdAndLog 'echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null'
    runCmdAndLog ${APT_CMD} update
    runCmdAndLog ${APT_INSTALL} \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin
else
    log "Docker already installed."
fi

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
    runCmdAndLog update-alternatives \
        --install ${USR_BIN_DIR}/docker-compose \
        docker-compose \
        "${DOCKER_COMPOSE_SWITCH_BIN}" \
        99
else
    log "Docker Switch already installed."
fi

# NeoVim
if ! [ -e "$(command -v nvim)" ]; then
    log "Installing NeoVim..."
    # Adds repo for latest neovim version
    runCmdAndLog add-apt-repository -y ppa:neovim-ppa/stable
    runCmdAndLog ${APT_CMD} update
    runCmdAndLog ${APT_INSTALL} neovim
    # Set neovim as default vim
    runCmdAndLog update-alternatives --set vi $(which nvim)
    runCmdAndLog update-alternatives --set vim $(which nvim)
else
    log "NeoVim already installed."
fi

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
log "Making sure python exists..."
PYTHON_BIN=/usr/bin/python
if ! [ -x "$(command -v python)" ] || ! [ -e ${PYTHON_BIN} ]; then
    log "Python is not installed."
    PYTHON3_BIN=$(command -v python3)
    if [ -x "${PYTHON3_BIN}" ]; then
        log "Symlinking python3 (${PYTHON3_BIN}) to (${PYTHON_BIN})..."
        ln -s "${PYTHON3_BIN}" "${PYTHON_BIN}"
    fi
fi

# ZSH and Prezto
# https://github.com/sorin-ionescu/prezto
log "Installing ZSH and Prezto..."
runCmdAndLog ${APT_INSTALL} zsh
ZSH_BIN=$(command -v zsh)
PREZTO_DIR="${HOME}/.zprezto"
PREZTORC_URL="https://raw.githubusercontent.com/yorch/ubuntu-server-bootstrap/main/.zpreztorc"
PREZTO_REPO_URL="https://github.com/sorin-ionescu/prezto.git"

if [ -x "${ZSH_BIN}" ]; then
    if ! [ -d "${PREZTO_DIR}" ]; then
        runCmdAndLog git clone --recursive "${PREZTO_REPO_URL}" "${PREZTO_DIR}"
        ${CURL_CMD} "${PREZTORC_URL}" -o "${PREZTO_DIR}/runcoms/zpreztorc"
        ${ZSH_BIN} -c "
            setopt EXTENDED_GLOB
            for rcfile in \"\${HOME}\"/.zprezto/runcoms/^README.md(.N); do
                ln -s \"\$rcfile\" \"\${HOME}/.\${rcfile:t}\"
            done
        "
        chsh -s /bin/zsh
    else
        log "Prezto already installed."
    fi
else
    log "ERROR - Could not find ZSH even though we tried to install it"
fi

# SpaceVim
log "Installing or updating SpaceVim..."
runCmdAndLog ${APT_INSTALL} fontconfig
runCmdAndLog "${CURL_CMD} https://spacevim.org/install.sh | bash"

# Enable multiplexer `byobu`
# byobu-enable

# Cleanup old packages
log "Cleaning up old packages..."
runCmdAndLog ${APT_CMD} autoremove

# Cleanup caches
log "Cleanup caches..."
runCmdAndLog ${APT_CMD} clean

echo
echo "-----------------------------------------------------------------------------------------------------"
log "All Done! You should restart the machine now!"
log "A log file is available at ${LOG_FILE}"
echo "-----------------------------------------------------------------------------------------------------"
echo
