#!/bin/bash

# =============================================================================
# CORE CONSTANTS
# =============================================================================
# Organization and project constants that rarely change
# These are the foundation values for the entire sdk

readonly ORG_NAME="diseec"
readonly SDK_NAME="sdk"

# Registry and repository configuration
readonly IMAGE_REGISTRY_URL="image.registry.$ORG_NAME.com"
readonly REPO_HUB_URL="github.com/$ORG_NAME"
readonly SDK_IMAGE="$IMAGE_REGISTRY_URL/$SDK_NAME"
readonly SDK_PACKAGE_NAME="$ORG_NAME/$SDK_NAME"
readonly SDK_RELATIVE_PATH="node_modules/$SDK_PACKAGE_NAME"

# Container paths
readonly GIT_DIR_CONTAINER="/.git"
readonly WORK_DIR_CONTAINER="/work"

