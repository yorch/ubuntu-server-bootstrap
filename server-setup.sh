#!/bin/bash

# Timezone
timedatectl set-timezone America/New_York

# Locales
locale-gen en_US.UTF-8
locale-gen en_CA.UTF-8

# Update all current packages
apt-get update && apt-get upgrade -y

# Cleanup old packages
apt-get autoremove -y

# Tools
apt-get install -y \
    curl \
    git \
    htop \
    vim \
    wget

# Install Docker
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update && apt-get install -y docker-ce

# Install Docker Compose
DOCKER_COMPOSE_BIN=/usr/local/bin/docker-compose
curl -L \
    "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" \
    -o ${DOCKER_COMPOSE_BIN}
chmod +x ${DOCKER_COMPOSE_BIN}

# Install SpeedTest
SPEEDTEST_BIN=/usr/local/bin/speedtest-cli
wget \
    -O ${SPEEDTEST_BIN} \
    https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod +x ${SPEEDTEST_BIN}

# Install ZSH and Prezto
apt-get install -y zsh
curl -s https://raw.githubusercontent.com/yorch/server-simple-setup/master/setup-prezto.sh | zsh
chsh -s /bin/zsh
