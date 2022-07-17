#!/bin/bash

USR_BIN_DIR=/usr/local/bin

# Timezone
timedatectl set-timezone America/New_York

# Locales
locale-gen \
    en_US.UTF-8 \
    en_CA.UTF-8

# Update all current packages
apt-get update && apt-get upgrade -y && apt autoremove -y

# Tools
apt-get install -y \
    byobu \
    curl \
    git \
    htop \
    silversearcher-ag \
    tig \
    vim \
    wget

# Install Docker
echo 'Installing Docker...'
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update && \
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin

# Install Docker Compose
# https://github.com/docker/compose
DOCKER_CLI_PLUGINS_DIR='/usr/local/lib/docker/cli-plugins'
DOCKER_COMPOSE_BIN="${DOCKER_CLI_PLUGINS_DIR}/docker-compose"
DOCKER_COMPOSE_VERSION='v2.6.1'
DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)"
if ! [ -e "${DOCKER_COMPOSE_BIN}" ]; then
    mkdir -p "${DOCKER_CLI_PLUGINS_DIR}"
    echo "Installing Docker Compose version ${DOCKER_COMPOSE_VERSION}..."
    curl -sSL "${DOCKER_COMPOSE_URL}" -o "${DOCKER_COMPOSE_BIN}"
    chmod +x "${DOCKER_COMPOSE_BIN}"
    echo "Docker Compose installed."
else
    echo "Docker Compose already installed."
fi

# Install Docker Compose Switch (to ease transition from Docker Compose v1)
DOCKER_COMPOSE_SWITCH_BIN="${USR_BIN_DIR}/compose-switch"
DOCKER_COMPOSE_SWITCH_VERSION="v1.0.5"
DOCKER_COMPOSE_SWITCH_URL="https://github.com/docker/compose-switch/releases/download/${DOCKER_COMPOSE_SWITCH_VERSION}/docker-compose-linux-amd64"
if ! [ -e ${DOCKER_COMPOSE_SWITCH_BIN} ]; then
    echo "Installing Docker Switch version ${DOCKER_COMPOSE_SWITCH_VERSION}..."
    curl -sSL "${DOCKER_COMPOSE_SWITCH_URL}" -o "${DOCKER_COMPOSE_SWITCH_BIN}"
    chmod +x "${DOCKER_COMPOSE_SWITCH_BIN}"
    # Set Docker Compose Switch to replace Docker Compose v1
    update-alternatives --install ${USR_BIN_DIR}/docker-compose docker-compose "${DOCKER_COMPOSE_SWITCH_BIN}" 99
    echo "Docker Switch installed."
else
    echo "Docker Switch already installed."
fi

# Install NeoVim
# Adds repo for latest neovim version
add-apt-repository -y ppa:neovim-ppa/stable
apt-get update && apt-get install -y neovim
# Set neovim as default vim
update-alternatives --set vi $(which nvim)
update-alternatives --set vim $(which nvim)

# Install SpeedTest
# https://github.com/sivel/speedtest-cli
SPEEDTEST_BIN="${USR_BIN_DIR}/speedtest-cli"
SPEEDTEST_VERSION='master'
# SPEEDTEST_VERSION='v2.1.2'
if ! [ -e ${SPEEDTEST_BIN} ]; then
    echo 'Installing SpeedTest CLI...'
    curl -sSL \
        "https://raw.githubusercontent.com/sivel/speedtest-cli/${SPEEDTEST_VERSION}/speedtest.py" \
        -o ${SPEEDTEST_BIN}
    chmod +x ${SPEEDTEST_BIN}
else
    echo 'SpeedTest CLI already installed.'
fi

# Make sure `python` exists
PYTHON_BIN=/usr/bin/python
if ! [ -x "$(command -v python)" ] || ! [ -e ${PYTHON_BIN} ]; then
    echo 'Python is not installed, trying to symlink python3...'
    if [ -x "$(command -v python3)" ]; then
        PYTHON3_BIN=$(command -v python3)
        echo "Symlinking python3 (${PYTHON3_BIN}) to python (${PYTHON_BIN})..."
        ln -s ${PYTHON3_BIN} ${PYTHON_BIN}
    fi
fi

# Install ZSH and Prezto
# https://github.com/sorin-ionescu/prezto
echo 'Installing ZSH and Prezto...'
apt-get install -y zsh
curl -sSL https://raw.githubusercontent.com/yorch/server-simple-setup/main/setup-prezto.sh | zsh
chsh -s /bin/zsh

# Install SpaceVim
curl -sLf https://spacevim.org/install.sh | bash

# Cleanup old packages
apt-get autoremove -y && apt-get clean

echo
echo 'All Done! You should restart the machine now'
