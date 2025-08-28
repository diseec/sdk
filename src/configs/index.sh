#!/bin/bash

# =============================================================================
# ENVIRONMENT VARIABLES INITIALIZATION
# =============================================================================
# Main environment file that loads all modules and initializes variables

# Source all utility modules
source $KIT_DIR/src/configs/constants.sh
source $KIT_DIR/src/configs/utils/git_fallback_utils.sh
source $KIT_DIR/src/configs/utils/path-discovery.sh
source $KIT_DIR/src/configs/utils/env_detection.sh

# =============================================================================
# COMPUTED PATHS AND DIRECTORIES
# =============================================================================

# Discover project root directory
ROOT_DIR="$(con_uti_cli_auto_discovery)"
readonly ROOT_DIR

# Kit and cli_main paths
readonly KIT_SRC_DIR="$KIT_DIR/src"
readonly CLI_MAIN="$ROOT_DIR/cli"
readonly CLI_CORE="$KIT_SRC_DIR/cli.sh"

# Organization directories
ORG_DIR="$(get_org_dir)"
readonly ORG_DIR

ORG_CACHE_DIR="$(get_cache_dir)"
readonly ORG_CACHE_DIR

# =============================================================================
# ENVIRONMENT STATE VARIABLES
# =============================================================================

# Container detection
IS_IN_CONTAINER="$(con_uti_is_in_container)"
readonly IS_IN_CONTAINER

# Project structure detection
IS_MONOREPO="$(con_uti_is_monorepo)"
readonly IS_MONOREPO

HAS_SUBMODULES="$(con_uti_has_submodules)"
readonly HAS_SUBMODULES

# Version information
VERSION="$(con_uti_get_kit_version)"
readonly VERSION

# Git repository information
REPO_URL="$(con_uti_get_repo_url)"
readonly REPO_URL

REPO_NAME="$(con_uti_get_repo_name)"
readonly REPO_NAME

CURRENT_BRANCH="$(con_uti_get_current_branch)"
readonly CURRENT_BRANCH

######

con_uti_validate_environment