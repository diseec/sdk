#!/bin/bash

vars=( \
    D_GLOB_ENV \
    D_GLOB_DEBUG \
    D_GLOB_LOG_LEVEL \
    D_GLOB_RECURSIVE \
    D_GLOB_TTY \
    D_GLOB_PATCH \
    D_VERSION \
    D_CTX_DIR \
    D_SDK_DIR \
    D_REPO_NAME \
    D_SDK_NAME \
    D_GIT_DIR \
    D_ORG_CACHE_DIR \
    D_REGISTRY_URL \
    D_CONT_CTX_DIR \
    D_CONT_GIT_DIR \
    D_TARGET_CTX_DIR \
)

# export "${vars[@]}" # reduces control

for v in "${vars[@]}"; do
    val="${!v}"
    # print shell-escaped export statements (works with spaces, newlines, etc.)
    printf '%s=%s\n' "$v" "$(printf '%q' "$val")"
done
