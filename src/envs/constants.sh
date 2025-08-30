#!/bin/bash

# =============================================================================
# CORE CONSTANTS
# =============================================================================
# Organization and project constants that rarely change
# These are the foundation values for the entire kit

readonly ORG_NAME="diseec"
readonly KIT_NAME="kit"
readonly PROJECT_MOUNT_DIR="/vise"

# Registry and repository configuration
readonly IMAGE_REGISTRY_URL="image.registry.$ORG_NAME.com"
readonly KIT_IMAGE="$IMAGE_REGISTRY_URL/$KIT_NAME"
readonly REPO_HUB_URL="github.com/$ORG_NAME"
readonly KIT_PACKAGE_NAME="@diseec/$KIT_NAME"
readonly KIT_RELATIVE_PATH="node_modules/$KIT_PACKAGE_NAME"

# Git configuration
readonly GIT_MOUNT_DIR="/.git"

