#!/bin/bash

sdk_boo_env_setup_environment() {
    # =============================================================================
    # ENVIRONMENT VARIABLES INITIALIZATION
    # =============================================================================
    # Main environment file that loads all modules and initializes variables

    # Source all utility modules
    source $D_SDK_DIR/bootstrap/environment/constants.sh
    source $D_SDK_DIR/bootstrap/environment/utils/git_fallback_utils.sh
    source $D_SDK_DIR/bootstrap/environment/utils/cli_auto_discovery.sh
    source $D_SDK_DIR/bootstrap/environment/utils/env_detection.sh
    source $D_SDK_DIR/bootstrap/environment/utils/validate_environment.sh

    # =============================================================================
    # STORE ORIGINAL ENVIRONMENT VARIABLES
    # =============================================================================

    readonly D_INI_ARGS="$@"
    readonly D_INI_PWD="$PWD"

    : ${D_D_CLI_EXECUTED:=false}
    readonly D_D_CLI_EXECUTED
    
    : ${D_SDK_CLI_EXECUTED:=false}
    readonly D_SDK_CLI_EXECUTED

    # =============================================================================
    # COMPUTED PATHS AND DIRECTORIES
    # =============================================================================

    # Discover project root directory if not already set
    if [ -z "${D_CTX_DIR:-}" ]; then
        D_CTX_DIR="$(sdk_boo_env_uti_cli_auto_discovery)"
    fi
    readonly D_CTX_DIR

    readonly D_CLI_SDK="$D_SDK_DIR/$D_SDK_NAME"
    readonly D_CLI_CORE="$D_SDK_DIR/cli.sh"

    # Kit and CLI paths
    if [ -n "$D_CTX_DIR" ]; then
        if [ "$D_SDK_CLI_EXECUTED" = "true" ]; then
            readonly D_CLI_STUB="$D_CLI_SDK"
            readonly D_CLI_STUB_CONTAINER="$D_CTX_DIR_CONTAINER/$D_SDK_NAME"
        else
            readonly D_CLI_STUB="$D_CTX_DIR/$D_CLI_LOCAL_NAME"
            readonly D_CLI_STUB_CONTAINER="$D_CTX_DIR_CONTAINER/$D_CLI_LOCAL_NAME"
        fi
    fi

    D_CTX_DIR_HOST="$(sdk_boo_env_uti_get_kit_target_dit)"

    # Organization directories
    D_ORG_DIR="$(sdk_boo_env_uti_get_org_dir)"
    readonly D_ORG_DIR

    D_ORG_CACHE_DIR="$(sdk_boo_env_uti_get_cache_dir)"
    readonly D_ORG_CACHE_DIR

    # =============================================================================
    # ENVIRONMENT STATE VARIABLES
    # =============================================================================

    # Container detection
    D_IS_IN_CONTAINER="$(sdk_boo_env_uti_is_in_container)"
    readonly D_IS_IN_CONTAINER

    D_HAS_SUBMODULES="$(sdk_boo_env_uti_has_submodules)"
    readonly D_HAS_SUBMODULES

    # Version information
    D_VERSION="$(sdk_boo_env_uti_get_kit_version)"
    readonly D_VERSION

    # Git repository information
    D_GIT_DIR="$(sdk_boo_env_uti_get_git_dir)"
    readonly D_GIT_DIR

    D_REPO_URL="$(sdk_boo_env_uti_get_repo_url)"
    readonly D_REPO_URL

    D_REPO_NAME="$(sdk_boo_env_uti_get_repo_name)"
    readonly D_REPO_NAME

    D_CURRENT_BRANCH="$(sdk_boo_env_uti_get_current_branch)"
    readonly D_CURRENT_BRANCH

    # =============================================================================
    # FINAL VALIDATIONS
    # =============================================================================

    # Validate essential environment variables
    sdk_boo_env_uti_validate_environment
}

