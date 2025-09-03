#!/bin/bash

# =============================================================================
# ENVIRONMENT VARIABLES INITIALIZATION
# =============================================================================
# Main environment file that loads all modules and initializes variables

# Source all utility modules
source $KIT_DIR/src/core/envs/constants.sh
source $KIT_DIR/src/core/envs/utils/source_once.sh
source $KIT_DIR/src/core/envs/utils/git_fallback_utils.sh
source $KIT_DIR/src/core/envs/utils/cli_auto_discovery.sh
source $KIT_DIR/src/core/envs/utils/env_detection.sh
source $KIT_DIR/src/core/envs/utils/validate_environment.sh

# =============================================================================
# COMPUTED PATHS AND DIRECTORIES
# =============================================================================

# Discover project root directory
ROOT_DIR="$(src_cor_env_uti_cli_auto_discovery)"
readonly ROOT_DIR

# Kit and CLI paths
readonly KIT_SRC_DIR="$KIT_DIR/src"
readonly CLI_MAIN="$ROOT_DIR/cli"
readonly CLI_CORE="$KIT_SRC_DIR/cli.sh"

KIT_TARGET_DIR="$(src_cor_env_uti_get_kit_target_dit)"

# Organization directories
ORG_DIR="$(src_cor_env_uti_get_org_dir)"
readonly ORG_DIR

ORG_CACHE_DIR="$(src_cor_env_uti_get_cache_dir)"
readonly ORG_CACHE_DIR

# =============================================================================
# ENVIRONMENT STATE VARIABLES
# =============================================================================

# Container detection
IS_IN_CONTAINER="$(src_cor_env_uti_is_in_container)"
readonly IS_IN_CONTAINER

HAS_SUBMODULES="$(src_cor_env_uti_has_submodules)"
readonly HAS_SUBMODULES

# Version information
VERSION="$(src_cor_env_uti_get_kit_version)"
readonly VERSION

# Git repository information
GIT_DIRECTORY="$(src_cor_env_uti_get_git_dir)"
readonly GIT_DIRECTORY

REPO_URL="$(src_cor_env_uti_get_repo_url)"
readonly REPO_URL

REPO_NAME="$(src_cor_env_uti_get_repo_name)"
readonly REPO_NAME

CURRENT_BRANCH="$(src_cor_env_uti_get_current_branch)"
readonly CURRENT_BRANCH

######

src_cor_env_uti_validate_environment