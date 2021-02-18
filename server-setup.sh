#!/bin/bash

# Timezone
timedatectl set-timezone America/New_York

# Locales
locale-gen \
    en_US.UTF-8 \
    en_CA.UTF-8

# Update all current packages
apt-get update && apt-get upgrade -y

# Tools
apt-get install -y \
    byobu \
    curl \
    git \
    htop \
    neovim \
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
DOCKER_COMPOSE_BIN='/usr/local/bin/docker-compose'
DOCKER_COMPOSE_VERSION='1.28.3'
if ! [ -e ${DOCKER_COMPOSE_BIN} ]; then
    echo 'Installing Docker Compose...'
    curl -sSL \
        "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o ${DOCKER_COMPOSE_BIN}
    chmod +x ${DOCKER_COMPOSE_BIN}
fi

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

# Cleanup old packages
apt-get autoremove -y
apt-get clean

echo
echo 'All Done! You should restart the machine now'
