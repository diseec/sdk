#!/bin/bash

CLI() {
    source "$_CLI" "$@"
}

CLI_BASE() {
    source "$_CLI_BASE" "$@"
}

SRC_KIT() {
    path=$1; shift; source "$KIT_SRC_DIR/$path" "$@"
}

SAFELY() {
    if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then 
        CLI safely "$@"; return 0
    fi
    return 1
}

SAFELY_SRC_KIT() {
    local src=$1; shift
    if [ -z "$src" ]; then
        message 41 "error" "Source path is required in SAFELY_SRC_KIT at $BASH_SOURCE:$LINENO"
        return 1
    fi
    if [ $# -eq 0 ]; then
        message 41 "error" "No additional arguments provided in SAFELY_SRC_KIT at $BASH_SOURCE:$LINENO"
        return 1
    fi
    SAFELY "$@" && shift && SRC_KIT "$src" "$@"
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
