#!/bin/bash

_prettier() {
    # cli_main $KIT_NAME run --quiet prettier "$@"
    prettier "$@"
}

_node() {
    # cli_main $KIT_NAME run --quiet node "$@"
    node "$@"
}

_npm() {
    # cli_main $KIT_NAME run --quiet npm "$@"
    npm "$@"
}

_docker() {
    # cli_main $KIT_NAME run --quiet docker "$@"

    env \
    ROOT_DIR="$ROOT_DIR" \
    REPO_NAME="$REPO_NAME" \
    KIT_DIR="$KIT_DIR" \
    KIT_NAME="$KIT_NAME" \
    GIT_DIRECTORY="$GIT_DIRECTORY" \
    ORG_CACHE_DIR="$ORG_CACHE_DIR" \
    IMAGE_REGISTRY_URL="$IMAGE_REGISTRY_URL" \
    TARGET_MOUNTED_DIR="$TARGET_MOUNTED_DIR" \
    GIT_MOUNT_DIR="$GIT_MOUNT_DIR" \
    KIT_TARGET_DIR="$KIT_TARGET_DIR" \
    docker "$@"
}

_jq() {
    # cli_main $KIT_NAME run --quiet yq "$@"
    jq "$@"
}

_yq() {
    # cli_main $KIT_NAME run --quiet yq "$@"
    yq "$@"
}

_openssl() {
    # cli_main $KIT_NAME run --quiet openssl "$@"
    openssl "$@"
}

_git() {
    # cli_main $KIT_NAME run --quiet git "$@"
    if [ "$IS_IN_KIT_CONTAINER" = "true" ]; then
        GIT_WORK_TREE="$ROOT_DIR" GIT_DIR="$GIT_DIRECTORY" git "$@"
    else
        git "$@"
    fi
}

_gh() {
    # cli_main $KIT_NAME run --quiet gh "$@"
    if [ "$IS_IN_KIT_CONTAINER" = "true" ]; then
        GIT_WORK_TREE="$ROOT_DIR" GIT_DIR="$GIT_DIRECTORY" gh "$@"
    else
        gh "$@"
    fi
}
