#!/bin/bash

# =============================================================================
# ENVIRONMENT VARIABLES INITIALIZATION
# =============================================================================
# Main environment file that loads all modules and initializes variables

# Source all utility modules
source $KIT_DIR/src/envs/constants.sh
source $KIT_DIR/src/envs/utils/git_fallback_utils.sh
source $KIT_DIR/src/envs/utils/cli_auto_discovery.sh
source $KIT_DIR/src/envs/utils/env_detection.sh
source $KIT_DIR/src/envs/utils/validate_environment.sh

# =============================================================================
# COMPUTED PATHS AND DIRECTORIES
# =============================================================================

# Discover project root directory
ROOT_DIR="$(env_uti_cli_auto_discovery)"
readonly ROOT_DIR

# Kit and CLI paths
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
IS_IN_CONTAINER="$(env_uti_is_in_container)"
readonly IS_IN_CONTAINER

HAS_SUBMODULES="$(env_uti_has_submodules)"
readonly HAS_SUBMODULES

# Version information
VERSION="$(env_uti_get_kit_version)"
readonly VERSION

# Git repository information
readonly GIT_WORK_TREE="$ROOT_DIR"

GIT_DIR="$(env_uti_get_git_dir)"
readonly GIT_DIR

REPO_URL="$(env_uti_get_repo_url)"
readonly REPO_URL

REPO_NAME="$(env_uti_get_repo_name)"
readonly REPO_NAME

CURRENT_BRANCH="$(env_uti_get_current_branch)"
readonly CURRENT_BRANCH

######

env_uti_validate_environment