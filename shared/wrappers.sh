#!/bin/bash

_prettier() {
    # cli_ctx $D_SDK_NAME run --quiet prettier "$@"
    prettier "$@"
}

_node() {
    # cli_ctx $D_SDK_NAME run --quiet node "$@"
    node "$@"
}

_npm() {
    # cli_ctx $D_SDK_NAME run --quiet npm "$@"
    npm "$@"
}

_docker() {
    # cli_ctx $D_SDK_NAME run --quiet docker "$@"
    docker "$@"
}

_jq() {
    # cli_ctx $D_SDK_NAME run --quiet yq "$@"
    jq "$@"
}

_yq() {
    # cli_ctx $D_SDK_NAME run --quiet yq "$@"
    yq "$@"
}

_openssl() {
    # cli_ctx $D_SDK_NAME run --quiet openssl "$@"
    openssl "$@"
}

_git() {
    # cli_ctx $D_SDK_NAME run --quiet git "$@"
    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        GIT_WORK_TREE="$D_CTX_DIR" GIT_DIR="$D_GIT_DIR" git "$@"
    else
        git "$@"
    fi
}

_gh() {
    # cli_ctx $D_SDK_NAME run --quiet gh "$@"
    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        GIT_WORK_TREE="$D_CTX_DIR" GIT_DIR="$D_GIT_DIR" gh "$@"
    else
        gh "$@"
    fi
}
