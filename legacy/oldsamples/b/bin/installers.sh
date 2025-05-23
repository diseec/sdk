#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

install_common_services() {
# Determine the distribution
distro=$(lsb_release -i -s)

if [ "$distro" = "Ubuntu" -o "$distro" = "Debian" ]; then
  # Install packages for Docker
  apt-get install -y \
    git \
    curl \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

  # Add Docker's official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

  # Set up the Docker stable repository
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

  # Install Docker
  apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

  # Install Docker Compose
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
elif [ "$distro" = "Alpine" ]; then
  # Install Docker, Docker Compose, and Git
  apk add docker docker-compose git
  rc-update add docker boot
else
  echo "Unsupported distribution: $distro"
fi
}

install_node_modules() {
  message "Installing monorepo's node modules via yarn..."

  if [ "$DEV_DOCKERLESS" == "0" ]; then
    message "Starting node service..."
    docker run \
        --name installing_node_modules \
        -v $(get_root):/base \
        -v satyp-node_modules:/base/node_modules \
        -w /base \
        node:latest \
        yarn install -y

    message "Cleaning service..."
    docker rm -f installing_node_modules 
  fi

  (cd $(get_root) && yarn install -y)
}