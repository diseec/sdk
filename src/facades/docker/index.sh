#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

export  IMAGE_REGISTRY_URL \
        REPO_NAME \
        ROOT_DIR \
        ORG_CACHE_DIR \
        KIT_NAME \
        KIT_DIR \
        PROJECT_MOUNT_DIR_NAME

source "$KIT_SRC_DIR/facades/docker/up-development.sh"
source "$KIT_SRC_DIR/facades/docker/up-production.sh"
source "$KIT_SRC_DIR/facades/docker/execute.sh"
