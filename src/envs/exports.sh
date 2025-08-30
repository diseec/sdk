#!/bin/bash

vars=( \
    ROOT_DIR \
    REPO_NAME \
    KIT_DIR \
    KIT_NAME \
    GIT_DIRECTORY \
    ORG_CACHE_DIR \
    IMAGE_REGISTRY_URL \
    TARGET_MOUNTED_DIR \
    GIT_MOUNT_DIR \
)

# export "${vars[@]}" # reduces control

for v in "${vars[@]}"; do
    val="${!v}"
    # print shell-escaped export statements (works with spaces, newlines, etc.)
    printf '%s=%s\n' "$v" "$(printf '%q' "$val")"
done
