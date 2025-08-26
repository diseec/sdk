#!/bin/bash

# =============================================================================
# ENVIRONMENT VARIABLES INITIALIZATION
# =============================================================================
# Main environment file that loads all modules and initializes variables

# Source all utility modules
source $KIT_DIR/src/config/constants.sh
source $KIT_DIR/src/facades/git/utils.sh
source $KIT_DIR/src/config/utils/path-discovery.sh
source $KIT_DIR/src/config/utils/env-detection.sh

# =============================================================================
# COMPUTED PATHS AND DIRECTORIES
# =============================================================================

# Discover project root directory
ROOT_DIR="$(auto_discover_project_root_dir)"
readonly ROOT_DIR

# Kit and CLI paths
readonly KIT_SRC_DIR="$KIT_DIR/src"
readonly CLI="$ROOT_DIR/cli"
readonly CLI_BASE="$KIT_SRC_DIR/cli.sh"

# Organization directories
ORG_DIR="$(get_org_dir)"
readonly ORG_DIR

ORG_CACHE_DIR="$(get_cache_dir)"
readonly ORG_CACHE_DIR

# =============================================================================
# ENVIRONMENT STATE VARIABLES
# =============================================================================

# Network connectivity
if [ -z "$IS_ONLINE" ]; then
    IS_ONLINE="$(is_online)"
fi
readonly IS_ONLINE

# Container detection
IS_IN_CONTAINER="$(is_in_container)"
readonly IS_IN_CONTAINER

# Project structure detection
IS_MONOREPO="$(is_monorepo)"
readonly IS_MONOREPO

HAS_SUBMODULES="$(has_submodules)"
readonly HAS_SUBMODULES

# Version information
VERSION="$(get_kit_version)"
readonly VERSION

# Git repository information
REPO_URL="$(get_repo_url)"
readonly REPO_URL

REPO_NAME="$(get_repo_name)"
readonly REPO_NAME

CURRENT_BRANCH="$(get_current_branch)"
readonly CURRENT_BRANCH

# =============================================================================
# ENVIRONMENT VALIDATION
# =============================================================================

validate_environment() {
    local errors=0
    
    # Check required directories
    if [ ! -d "$ROOT_DIR" ]; then
        echo "Error: ROOT_DIR not found: $ROOT_DIR" >&2
        errors=$((errors + 1))
    fi
    
    if [ ! -d "$KIT_DIR" ]; then
        echo "Error: KIT_DIR not found: $KIT_DIR" >&2
        errors=$((errors + 1))
    fi
    
    # Check required files
    if [ ! -f "$CLI" ]; then
        echo "Warning: CLI not found: $CLI" >&2
    fi
    
    return $errors
}
