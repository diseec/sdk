#!/bin/bash

vars=( \
    D_GLOBAL_ENV \
    D_GLOBAL_DEBUG \
    D_GLOBAL_LOG_LEVEL \
    D_GLOBAL_IS_RECURSIVE \
    D_GLOBAL_TTY_AVAILABLE \
    D_GLOBAL_SDK_PATCH_FORCE \
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
    D_HOST_CTX_DIR \
)

# export "${vars[@]}" # reduces control

for v in "${vars[@]}"; do
    val="${!v}"
    # print shell-escaped export statements (works with spaces, newlines, etc.)
    printf '%s=%s\n' "$v" "$(printf '%q' "$val")"
done
