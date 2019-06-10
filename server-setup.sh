#!/bin/bash

# Timezone
timedatectl set-timezone America/New_York

# Locales
locale-gen en_US.UTF-8
locale-gen en_CA.UTF-8

apt-get update

# Tools
apt-get install -y git curl wget htop

# Install Docker
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update && apt-get install -y docker-ce

# Install ZSH and Prezto
apt-get install -y zsh
curl -s https://gist.githubusercontent.com/yorch/635b9bd060007af01e904e70b319ac2a/raw/820b75b5c2ac4f36d135325211fcc66a02899fa8/setup-prezto.sh | zsh
chsh -s /bin/zsh
