#!/bin/bash

vars=( \
    ROOT_DIR \
    REPO_NAME \
    KIT_DIR \
    KIT_NAME \
    GIT_DIR \
    ORG_CACHE_DIR \
    IMAGE_REGISTRY_URL \
    PROJECT_MOUNT_DIR \
    GIT_MOUNT_DIR \
)

export "${vars[@]}"

for v in "${vars[@]}"; do
    val="${!v}"
    # print shell-escaped export statements (works with spaces, newlines, etc.)
    printf '%s=%s\n' "$v" "$(printf '%q' "$val")"
done
