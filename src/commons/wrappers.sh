#!/bin/bash

_prettier() {
  # $CLI $KIT_NAME run --no-message prettier "$@"
  prettier "$@"
}

_node() {
  # $CLI $KIT_NAME run --no-message node "$@"
  node "$@"
}

_npm() {
  # $CLI $KIT_NAME run --no-message npm "$@"
  npm "$@"
}

_docker() {
  # $CLI $KIT_NAME run --no-message docker "$@"
  docker "$@"
}

_yq() {
  # $CLI $KIT_NAME run --no-message yq "$@"
  yq "$@"
}

_openssl() {
  # $CLI $KIT_NAME run --no-message openssl "$@"
  openssl "$@"
}

_git() {
  # $CLI $KIT_NAME run --no-message git "$@"
  git "$@"
}

_gh() {
  # $CLI $KIT_NAME run --no-message gh "$@"
  gh "$@"
}
