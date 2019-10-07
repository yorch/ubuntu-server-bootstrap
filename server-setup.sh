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
apt-get install -y git curl wget htop vim

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

# Install ZSH and Prezto
apt-get install -y zsh
curl -s https://raw.githubusercontent.com/yorch/server-simple-setup/master/setup-prezto.sh | zsh
chsh -s /bin/zsh
