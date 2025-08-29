#!/bin/bash

cli_main() {
    source "$CLI_MAIN" "$@"
}

cli_core() {
    source "$CLI_CORE" "$@"
}

force_safe() {
    if [ "$IS_IN_KIT_CONTAINER" = "true" ];
        then return 1
        else cli_main safely "$@"; return 0
    fi
}

# external api wrappers

_prettier() {
    # cli_main $KIT_NAME run --no-message prettier "$@"
    prettier "$@"
}

_node() {
    # cli_main $KIT_NAME run --no-message node "$@"
    node "$@"
}

_npm() {
    # cli_main $KIT_NAME run --no-message npm "$@"
    npm "$@"
}

_docker() {
    # cli_main $KIT_NAME run --no-message docker "$@"
    docker "$@"
}

_jq() {
    # cli_main $KIT_NAME run --no-message yq "$@"
    jq "$@"
}

_jq() {
    # cli_main $KIT_NAME run --no-message yq "$@"
    yq "$@"
}

_openssl() {
    # cli_main $KIT_NAME run --no-message openssl "$@"
    openssl "$@"
}

_git() {
    # cli_main $KIT_NAME run --no-message git "$@"
    git "$@"
}

_gh() {
    # cli_main $KIT_NAME run --no-message gh "$@"
    gh "$@"
}
