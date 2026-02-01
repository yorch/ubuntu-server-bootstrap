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

SPINNER_PID=""
CURRENT_STEP=0

UBUNTU_SUPPORTED_VERSIONS=(
    "20.04"
    "22.04"
    "24.04"
)

###############################################################################
# Utils
###############################################################################

# Print the current date and time in a specific format
# Usage: currentDate
#   Returns: The current date and time in the format YYYY-MM-DD HH:MM:SS
#   Example: currentDate
#     Returns: 2023-10-01 12:34:56
function currentDate() {
    echo "$(date +'%Y-%m-%d %H:%M:%S')"
}

# Log a message with the current date and time
# Usage: log <message>
#   message: The message to log
#   Example: log "Hello, world!"
#     Logs: 2023-10-01 12:34:56 - Hello, world!
function log() {
    echo "$(currentDate) - ${@}"
}

# Log an error message with the current date and time in a specific color
# Usage: logError <message>
#   message: The message to log
#   Example: logError "An error occurred!"
#     Logs: 2023-10-01 12:34:56 - ERROR - An error occurred!
#   The message will be printed in red
function logError() {
    local MESSAGE="${@}"
    printf "\e[31mERROR - %s\e[m\n" "${MESSAGE}"
}

function catch() {
    stopSpinner 2>/dev/null || true
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
    stopSpinner 2>/dev/null || true
    echo "The script was interrupted, exiting"
}

# Run a command and log the output to a file
# Usage: runCmdAndLog <command>
#   command: The command to run
#   Example: runCmdAndLog "ls -l"
#     Logs: 2023-10-01 12:34:56 - Running command: ls -l
#     Logs the output of the command to the log file
#   The command will be run with the same environment as the script
#   The output will be appended to the log file
#   The log file will be created if it does not exist
#   The log file will be created in the same directory as the script
#   The log file will be named <script_name>_<timestamp>.log
function runCmdAndLog() {
    local CMD="${@}"
    echo "" &>> ${LOG_FILE}
    echo "================================================================================" &>> ${LOG_FILE}
    echo "$(currentDate) - Running command: ${CMD}" &>> ${LOG_FILE}
    echo "================================================================================" &>> ${LOG_FILE}
    startSpinner
    eval "${CMD}" &>> ${LOG_FILE}
    stopSpinner
}

# Start a background spinner to indicate progress
# Usage: startSpinner
#   Starts a spinner that shows elapsed time
#   The spinner runs in the background and updates every 0.2 seconds
#   Use stopSpinner to stop the spinner
function startSpinner() {
    # Only show spinner if stdout is a terminal
    if [ ! -t 1 ]; then
        return
    fi
    local START=$(date +%s)
    (
        local CHARS='/-\|'
        local I=0
        while true; do
            local NOW=$(date +%s)
            local ELAPSED=$(( NOW - START ))
            local MINS=$(( ELAPSED / 60 ))
            local SECS=$(( ELAPSED % 60 ))
            printf "\r  %s  %02d:%02d elapsed" "${CHARS:I%4:1}" "${MINS}" "${SECS}"
            I=$(( I + 1 ))
            sleep 0.2
        done
    ) &
    SPINNER_PID=$!
}

# Stop the background spinner
# Usage: stopSpinner
#   Stops the spinner started by startSpinner
#   Clears the spinner line from the terminal
function stopSpinner() {
    if [ ! -t 1 ]; then
        return
    fi
    if [ -n "${SPINNER_PID}" ] && kill -0 "${SPINNER_PID}" 2>/dev/null; then
        kill "${SPINNER_PID}" 2>/dev/null
        wait "${SPINNER_PID}" 2>/dev/null || true
        printf "\r\033[K"
    fi
    SPINNER_PID=""
}

# Log a step message with step counter and current date/time
# Usage: logStep <message>
#   message: The message to log
#   Increments the step counter and logs the message with the step number
#   Example: logStep "Installing tools..."
#     Logs: 2023-10-01 12:34:56 - [Step 1] Installing tools...
function logStep() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    log "[Step ${CURRENT_STEP}] $*"
}

# Get the latest release version for a GitHub repository
# Usage: getLatestReleaseForRepo <repo>
#   repo: The GitHub repository in the format <owner>/<repo>
#   Example: getLatestReleaseForRepo "owner/repo"
#     Returns: v1.0.0
#   The version will be extracted from the JSON response from the GitHub API
function getLatestReleaseForRepo {
    local REPO="${1}"
    ${CURL_CMD} "https://api.github.com/repos/${REPO}/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'
}

# Download a binary from the latest release of a GitHub repository
# Usage: downloadBinaryLatestRelease <repo> <asset_name> <output_file> [raw]
#   repo: The GitHub repository in the format <owner>/<repo>
#   asset_name: The name of the asset to download
#   output_file: The file to save the downloaded asset to
#   raw: If set to "raw", the asset will be downloaded from the raw URL
#   If not set, the asset will be downloaded from the release URL
#   (default: "false")
#   Example: downloadBinaryLatestRelease "owner/repo" "asset_name" "output_file"
#     Downloads the asset from the latest release of the repository
#     and saves it to the specified output file
#   The asset will be made executable
#   The asset will be downloaded from the raw URL if the "raw" parameter is set to "raw"
#   The asset will be downloaded from the release URL if the "raw" parameter is not set
function downloadBinaryLatestRelease {
    local REPO="${1}"
    local ASSET_NAME="${2}"
    local OUTPUT_FILE="${3}"
    local USE_RAW="${4}"
    downloadLatestReleaseArtifact "${REPO}" "${ASSET_NAME}" "${OUTPUT_FILE}" "${USE_RAW}"
    chmod +x "${OUTPUT_FILE}"
}

# Download a binary from the latest release of a GitHub repository
#
# Usage: downloadBinaryLatestRelease <repo> <asset_name> <output_file> [raw]
#   repo: The GitHub repository in the format <owner>/<repo>
#   asset_name: The name of the asset to download
#   output_file: The file to save the downloaded asset to
#   raw: If set to "raw", the asset will be downloaded from the raw URL
#   If not set, the asset will be downloaded from the release URL
#   (default: "false")
#   Example: downloadBinaryLatestRelease "owner/repo" "asset_name" "output_file"
#     Downloads the asset from the latest release of the repository
#     and saves it to the specified output file
function downloadLatestReleaseArtifact {
    local REPO="${1}"
    local ASSET_NAME="${2}"
    local OUTPUT_FILE="${3}"
    local USE_RAW="${4}"
    local VERSION=$(getLatestReleaseForRepo ${REPO})
    if [ "${USE_RAW}" = "raw" ]; then
        local URL="https://raw.githubusercontent.com/${REPO}/${VERSION}/${ASSET_NAME}"
    else
        local URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET_NAME}"
    fi
    log "Downloading from repo ${REPO} version ${VERSION} to file ${OUTPUT_FILE}"
    startSpinner
    ${CURL_CMD} "${URL}" -o "${OUTPUT_FILE}"
    stopSpinner
}

function getUbuntuVersion {
    local VERSION=$(grep -oP '(?<=DISTRIB_RELEASE=)[0-9\.]+' /etc/lsb-release)
    if [ -z "${VERSION}" ]; then
        logError "Could not determine Ubuntu version. Please run this script on Ubuntu."
        exit 1
    fi
    echo "${VERSION}"
}

###############################################################################
# Script
###############################################################################

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    logError "This script must be run as root. Please run it with sudo."
    exit 1
fi
# Check if the script is run on Ubuntu
if [ ! -f /etc/lsb-release ]; then
    logError "This script is only for Ubuntu. Please run it on Ubuntu."
    exit 1
fi
# Check if the script is run on supported Ubuntu versions
UBUNTU_VERSION=$(getUbuntuVersion)
log "Running on Ubuntu ${UBUNTU_VERSION}"
if [[ ! " ${UBUNTU_SUPPORTED_VERSIONS[@]} " =~ " ${UBUNTU_VERSION} " ]]; then
    logError "This script is only for Ubuntu ${UBUNTU_SUPPORTED_VERSIONS[*]}. Please run it on a supported version."
    exit 1
fi
# Check if the script is run on a supported architecture
if [ "$(uname -m)" != "x86_64" ]; then
    logError "This script is only for x86_64 architecture. Please run it on a supported architecture."
    exit 1
fi

echo
echo "-----------------------------------------------------------------------------------------------------"
log "Starting $(echo ${0}), this will take a few minutes depending on your system."
echo "-----------------------------------------------------------------------------------------------------"
echo

# Update all current packages
logStep "Upgrading existing packages..."
runCmdAndLog ${APT_CMD} update
runCmdAndLog ${APT_CMD} upgrade
runCmdAndLog ${APT_CMD} autoremove

# Timezone
logStep "Setting timezone to ${TIMEZONE}..."
if [ -x "$(command -v timedatectl)" ]; then
  runCmdAndLog timedatectl set-timezone ${TIMEZONE}
fi

# Locales
logStep "Setting locales to ${LOCALES[*]}..."
LOCALE_GEN=locale-gen
if ! [ -x "$(command -v ${LOCALE_GEN})" ]; then
  runCmdAndLog ${APT_INSTALL} locales
fi
runCmdAndLog ${LOCALE_GEN} ${LOCALES[@]}

# Tools
logStep "Installing tools..."
runCmdAndLog ${APT_INSTALL} \
    byobu \
    curl \
    fd-find \
    fzf \
    git \
    htop \
    ripgrep \
    silversearcher-ag \
    software-properties-common \
    tig \
    unzip \
    vim \
    wget \
    zip

# Install latest Docker version
if ! [ -e "$(command -v docker)" ]; then
    logStep "Installing Docker..."
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
    logStep "Docker already installed."
fi

# Docker Compose
# https://github.com/docker/compose
DOCKER_CLI_PLUGINS_DIR="/usr/local/lib/docker/cli-plugins"
DOCKER_COMPOSE_BIN="${DOCKER_CLI_PLUGINS_DIR}/docker-compose"
DOCKER_COMPOSE_REPO="docker/compose"
DOCKER_COMPOSE_ASSET="docker-compose-linux-$(uname -m)"
if ! [ -e "${DOCKER_COMPOSE_BIN}" ]; then
    mkdir -p "${DOCKER_CLI_PLUGINS_DIR}"
    logStep "Installing Docker Compose..."
    downloadBinaryLatestRelease "${DOCKER_COMPOSE_REPO}" "${DOCKER_COMPOSE_ASSET}" "${DOCKER_COMPOSE_BIN}"
else
    logStep "Docker Compose already installed."
fi

# Docker Compose Switch (to ease transition from Docker Compose v1)
DOCKER_COMPOSE_SWITCH_BIN="${USR_BIN_DIR}/compose-switch"
DOCKER_COMPOSE_SWITCH_REPO="docker/compose-switch"
DOCKER_COMPOSE_SWITCH_ASSET="docker-compose-linux-amd64"
if ! [ -e ${DOCKER_COMPOSE_SWITCH_BIN} ]; then
    logStep "Installing Docker Switch..."
    downloadBinaryLatestRelease "${DOCKER_COMPOSE_SWITCH_REPO}" "${DOCKER_COMPOSE_SWITCH_ASSET}" "${DOCKER_COMPOSE_SWITCH_BIN}"
    # Set Docker Compose Switch to replace Docker Compose v1
    runCmdAndLog update-alternatives \
        --install ${USR_BIN_DIR}/docker-compose \
        docker-compose \
        "${DOCKER_COMPOSE_SWITCH_BIN}" \
        99
else
    logStep "Docker Switch already installed."
fi

# NeoVim
if ! [ -e "$(command -v nvim)" ]; then
    logStep "Installing NeoVim..."
    # Adds repo for latest neovim version
    runCmdAndLog add-apt-repository -y ppa:neovim-ppa/stable
    runCmdAndLog ${APT_CMD} update
    runCmdAndLog ${APT_INSTALL} neovim
    # Set neovim as default vim
    runCmdAndLog update-alternatives --set vi $(which nvim)
    runCmdAndLog update-alternatives --set vim $(which nvim)
else
    logStep "NeoVim already installed."
fi

# SpeedTest
# https://github.com/sivel/speedtest-cli
SPEEDTEST_BIN="${USR_BIN_DIR}/speedtest-cli"
SPEEDTEST_REPO="sivel/speedtest-cli"
SPEEDTEST_ASSET="speedtest.py"
if ! [ -e ${SPEEDTEST_BIN} ]; then
    logStep "Installing SpeedTest CLI..."
    downloadBinaryLatestRelease "${SPEEDTEST_REPO}" "${SPEEDTEST_ASSET}" "${SPEEDTEST_BIN}" "raw"
else
    logStep "SpeedTest CLI already installed."
fi

# Make sure `python` exists
logStep "Making sure python exists..."
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
logStep "Installing ZSH and Prezto..."
runCmdAndLog ${APT_INSTALL} zsh
ZSH_BIN=$(command -v zsh)
PREZTO_DIR="${HOME}/.zprezto"
PREZTORC_URL="https://raw.githubusercontent.com/yorch/ubuntu-server-bootstrap/main/config/zpreztorc"
P10K_URL="https://raw.githubusercontent.com/yorch/ubuntu-server-bootstrap/main/config/p10k.zsh"
PREZTO_REPO_URL="https://github.com/sorin-ionescu/prezto.git"

if [ -x "${ZSH_BIN}" ]; then
    if ! [ -d "${PREZTO_DIR}" ]; then
        runCmdAndLog git clone --recursive "${PREZTO_REPO_URL}" "${PREZTO_DIR}"
        ${CURL_CMD} "${PREZTORC_URL}" -o "${PREZTO_DIR}/runcoms/zpreztorc"
        ${CURL_CMD} "${P10K_URL}" -o "${HOME}/.p10k.zsh"
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
# 20250523: No longer maintained, domain is no longer valid
# log "Installing or updating SpaceVim..."
# runCmdAndLog ${APT_INSTALL} fontconfig
# runCmdAndLog "${CURL_CMD} https://spacevim.org/install.sh | bash"

# Enable multiplexer `byobu`
# byobu-enable

# Cleanup old packages
logStep "Cleaning up old packages..."
runCmdAndLog ${APT_CMD} autoremove

# Cleanup caches
logStep "Cleanup caches..."
runCmdAndLog ${APT_CMD} clean

ELAPSED_MINS=$(( SECONDS / 60 ))
ELAPSED_SECS=$(( SECONDS % 60 ))

echo
echo "-----------------------------------------------------------------------------------------------------"
log "All Done in ${ELAPSED_MINS}m ${ELAPSED_SECS}s! You should restart the machine now!"
log "A log file is available at ${LOG_FILE}"
echo "-----------------------------------------------------------------------------------------------------"
echo
