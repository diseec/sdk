#!/bin/bash

_prettier() {
    # cli_main $SDK_NAME run --quiet prettier "$@"
    prettier "$@"
}

_node() {
    # cli_main $SDK_NAME run --quiet node "$@"
    node "$@"
}

_npm() {
    # cli_main $SDK_NAME run --quiet npm "$@"
    npm "$@"
}

_docker() {
    # cli_main $SDK_NAME run --quiet docker "$@"

    env \
    WORK_DIR="$WORK_DIR" \
    REPO_NAME="$REPO_NAME" \
    SDK_DIR="$SDK_DIR" \
    SDK_NAME="$SDK_NAME" \
    GIT_DIRECTORY="$GIT_DIRECTORY" \
    ORG_CACHE_DIR="$ORG_CACHE_DIR" \
    IMAGE_REGISTRY_URL="$IMAGE_REGISTRY_URL" \
    WORK_DIR_CONTAINER="$WORK_DIR_CONTAINER" \
    GIT_DIR_CONTAINER="$GIT_DIR_CONTAINER" \
    WORK_DIR_HOST="$WORK_DIR_HOST" \
    docker "$@"
}

_jq() {
    # cli_main $SDK_NAME run --quiet yq "$@"
    jq "$@"
}

_yq() {
    # cli_main $SDK_NAME run --quiet yq "$@"
    yq "$@"
}

_openssl() {
    # cli_main $SDK_NAME run --quiet openssl "$@"
    openssl "$@"
}

_git() {
    # cli_main $SDK_NAME run --quiet git "$@"
    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        GIT_WORK_TREE="$WORK_DIR" GIT_DIR="$GIT_DIRECTORY" git "$@"
    else
        git "$@"
    fi
}

_gh() {
    # cli_main $SDK_NAME run --quiet gh "$@"
    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        GIT_WORK_TREE="$WORK_DIR" GIT_DIR="$GIT_DIRECTORY" gh "$@"
    else
        gh "$@"
    fi
}
