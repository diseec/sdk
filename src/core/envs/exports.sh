#!/bin/bash

vars=( \
    WORK_DIR \
    REPO_NAME \
    SDK_DIR \
    SDK_NAME \
    GIT_DIRECTORY \
    ORG_CACHE_DIR \
    IMAGE_REGISTRY_URL \
    WORK_DIR_CONTAINER \
    GIT_DIR_CONTAINER \
    WORK_DIR_HOST \
)

# export "${vars[@]}" # reduces control

for v in "${vars[@]}"; do
    val="${!v}"
    # print shell-escaped export statements (works with spaces, newlines, etc.)
    printf '%s=%s\n' "$v" "$(printf '%q' "$val")"
done
