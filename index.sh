#!/bin/bash

# =============================================================================
# PROCESS COMMAND-LINE ARGUMENTS
# =============================================================================

export D_LOG_LEVEL="${D_LOG_LEVEL:-DEBUG}" # change this to info when app stable
_D_SDK_PATCH_FORCE="${_D_SDK_PATCH_FORCE:-false}"

_ARGS_ENVS_PROCESS=""; for arg in "$@"; do case "$arg" in
    --patch) _D_SDK_PATCH_FORCE="true" ;;
    --log-level=*) D_LOG_LEVEL="${arg#*=}";;
    # --log-level*) D_LOG_LEVEL="${arg#--log-level }";;
    --debug) D_LOG_LEVEL="DEBUG" ;;
*) _ARGS_ENVS_PROCESS="$_ARGS_ENVS_PROCESS \"$arg\"";; esac; done; eval set -- $(eval echo $_ARGS_ENVS_PROCESS);

# =============================================================================
# INITIALIZATION
# =============================================================================

# Guard to prevent multiple loadings
if [ "$_D_SDK_BOOTED" = "true" ]; then return 0; fi; _D_SDK_BOOTED="true";

# Set SDK source directory if not already set
if [ -z "${D_SDK_DIR:-}" ]; then
    D_SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Load common and bootstrap scripts
source "$D_SDK_DIR/shared/index.sh"
source "$D_SDK_DIR/bootstrap/index.sh"

# =============================================================================
#  SETUP ENVIRONMENT AND LOAD COMMON UTILITIES
# =============================================================================

# Setup environment variables
sdk_boo_env_setup_environment "$@"

# Set to context directory if available
if [ -d "$D_CTX_DIR" ]; then cd "$D_CTX_DIR"; fi

# Initialize debugger
sdk_boo_debug_init

# Add help command if no arguments provided
if [ $# -eq 0 ]; then set -- --help; fi
