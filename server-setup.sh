#!/bin/bash

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
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
# https://github.com/docker/compose
DOCKER_CLI_PLUGINS_DIR='/usr/local/lib/docker/cli-plugins'
DOCKER_COMPOSE_BIN="${DOCKER_CLI_PLUGINS_DIR}/docker-compose"
DOCKER_COMPOSE_VERSION='2.6.1'
if ! [ -e ${DOCKER_COMPOSE_BIN} ]; then
    mkdir -p "${DOCKER_CLI_PLUGINS_DIR}"
    echo "Installing Docker Compose version ${DOCKER_COMPOSE_VERSION}..."
    curl -sSL \
        "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" \
        -o ${DOCKER_COMPOSE_BIN}
    chmod +x ${DOCKER_COMPOSE_BIN}
fi

# Install Docker Compose Switch (to ease transition from Docker Compose v1)
curl -fL https://raw.githubusercontent.com/docker/compose-switch/master/install_on_linux.sh | sh

# Install NeoVim
# Adds repo for latest neovim version
add-apt-repository -y ppa:neovim-ppa/stable
apt-get update && apt-get install -y neovim
# Set neovim as default vim
update-alternatives --set vi $(which nvim)
update-alternatives --set vim $(which nvim)

# Install SpeedTest
# https://github.com/sivel/speedtest-cli
SPEEDTEST_BIN='/usr/local/bin/speedtest-cli'
SPEEDTEST_VERSION='master'
# SPEEDTEST_VERSION='v2.1.2'
if ! [ -e ${SPEEDTEST_BIN} ]; then
    echo 'Installing SpeedTest CLI...'
    curl -sSL \
        "https://raw.githubusercontent.com/sivel/speedtest-cli/${SPEEDTEST_VERSION}/speedtest.py" \
        -o ${SPEEDTEST_BIN}
    chmod +x ${SPEEDTEST_BIN}
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
curl -sSL https://raw.githubusercontent.com/yorch/server-simple-setup/master/setup-prezto.sh | zsh
chsh -s /bin/zsh

# Install SpaceVim
curl -sLf https://spacevim.org/install.sh | bash

# Cleanup old packages
apt-get autoremove -y && apt-get clean

echo
echo 'All Done! You should restart the machine now'
