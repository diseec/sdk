#!/bin/bash

vars=( \
    D_CTX_DIR \
    D_REPO_NAME \
    D_SDK_DIR \
    D_SDK_NAME \
    D_GIT_DIR \
    D_ORG_CACHE_DIR \
    D_REGISTRY_URL \
    D_CTX_DIR_CONTAINER \
    D_GIT_DIR_CONTAINER \
    D_CTX_DIR_HOST \
)

# export "${vars[@]}" # reduces control

for v in "${vars[@]}"; do
    val="${!v}"
    # print shell-escaped export statements (works with spaces, newlines, etc.)
    printf '%s=%s\n' "$v" "$(printf '%q' "$val")"
done
