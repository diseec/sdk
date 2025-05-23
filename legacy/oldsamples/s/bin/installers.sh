#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Deprecated
# install_missing_services() {
#   apt-get update
#   if ! [ -x "$(command -v docker)" -a -x "$(command -v git)" ]; then
#     install_essentials
#   fi
#   if ! [ -x "$(command -v node)" ]; then
#     install_node
#   fi
#   if ! [ -x "$(command -v yarn)" ]; then
#     install_yarn
#   fi
#   if ! [ -x "$(command -v php)" ]; then
#     install_php
#   fi
#   if ! [ -x "$(command -v composer)" ]; then
#     install_composer
#   fi
#   if ! [ -x "$(command -v mysql)" ]; then
#     install_mysql
#   fi
# }

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

install_node() {
    dpkg --get-selections | grep -v deinstall | grep node | awk '{print $1}' | xargs apt-get -y remove
    curl -sL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
}

install_yarn() {
  npm install -g yarn
}

install_php() {
  apt-get remove -y php*
  apt-get install -y software-properties-common
  add-apt-repository -y ppa:ondrej/php
  apt-get install -y \
  php8.2 \
  php8.2-mysql \
  php8.2-gd \
  php8.2-xml \
  php8.2-mbstring \
  php8.2-fileinfo \
  php8.2-sqlite3 \
  php8.2-curl
  
  # Enable PHP extensions
  phpenmod -v 8.2 pdo_mysql gd xml mbstring fileinfo pdo_sqlite pcntl curl
}

install_composer() {
  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer
}

install_mysql() {
  echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
  apt-get install -y mysql-server
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