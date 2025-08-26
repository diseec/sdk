#!/bin/bash

# Use these on high level cli file

CLI() {
    source "$_CLI" "$@"
}

CLI_BASE() {
    source "$_CLI_BASE" "$@"
}

SRC() {
    path=$1; shift; source "$KIT_SRC_DIR/$path" "$@"
}

SRC_SAFELY() {
    if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then 
        CLI on-bench "$c" "$@"; return 0
    fi
    SRC "$@"
}

# use these on lower level reverse recalls
_CLI_() {
    "$_CLI" "$@"
}

# external api wrappers

_prettier() {
  # CLI $KIT_NAME run --no-message prettier "$@"
  prettier "$@"
}

_node() {
  # CLI $KIT_NAME run --no-message node "$@"
  node "$@"
}

_npm() {
  # CLI $KIT_NAME run --no-message npm "$@"
  npm "$@"
}

_docker() {
  # CLI $KIT_NAME run --no-message docker "$@"
  docker "$@"
}

_yq() {
  # CLI $KIT_NAME run --no-message yq "$@"
  yq "$@"
}

_openssl() {
  # CLI $KIT_NAME run --no-message openssl "$@"
  openssl "$@"
}

_git() {
  # CLI $KIT_NAME run --no-message git "$@"
  git "$@"
}

_gh() {
  # CLI $KIT_NAME run --no-message gh "$@"
  gh "$@"
}
