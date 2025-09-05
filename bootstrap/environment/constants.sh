#!/bin/bash

# =============================================================================
# CORE CONSTANTS
# =============================================================================
# Organization and project constants that rarely change
# These are the foundation values for the entire sdk

readonly D_ORG_NAME="diseec"
readonly D_SDK_NAME="sdk"
readonly D_CLI_GLOBAL_NAME="D"
readonly D_CLI_LOCAL_NAME="cli"

# Registry and repository configuration
readonly D_REGISTRY_URL="image.registry.$D_ORG_NAME.com"
readonly D_REPOSITORY_URL="github.com/$D_ORG_NAME"
readonly D_SDK_IMAGE="$D_REGISTRY_URL/$D_SDK_NAME"
readonly D_SDK_NPM_PKG="@$D_ORG_NAME/$D_SDK_NAME"
readonly D_SDK_NPM_PATH="node_modules/$D_SDK_NPM_PKG"

# Container paths
readonly D_GIT_DIR_CONTAINER="/.git"
readonly D_CTX_DIR_CONTAINER="/ctx"

