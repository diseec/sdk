#!/bin/bash

# =============================================================================
# PROCESS COMMAND-LINE ARGUMENTS
# =============================================================================

export D_LOG_LEVEL="${D_LOG_LEVEL:-DEBUG}" # change this to info when app stable
export D_TTY_AVAILABLE="${D_TTY_AVAILABLE:-true}"  # TTY availability flag, true by default
export D_SDK_PATCH_FORCE="${D_SDK_PATCH_FORCE:-false}"
export D_IS_RECURSIVE="${D_IS_RECURSIVE:-false}"
export D_IS_QUIET="${D_IS_QUIET:-false}"

_ARGS_ENVS_PROCESS=""; _remaining_args=(); _found_command=false; for arg in "$@"; do
    if [ "$_found_command" = true ]; then
        _remaining_args+=("$arg")
    else
        case "$arg" in
            -q|--quiet)     D_IS_QUIET="true" ;;
            --patch)        D_SDK_PATCH_FORCE="true" ;;
            -r|--recursive) D_IS_RECURSIVE="true";;
            # --log-level*) D_LOG_LEVEL="${arg#--log-level }";;
            --debug)        D_LOG_LEVEL="DEBUG" ;;
            --log-level=*)  D_LOG_LEVEL="${arg#*=}";;
            *) _remaining_args+=("$arg"); _found_command=true;;
        esac
    fi
done; set -- "${_remaining_args[@]}";

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
source "$D_SDK_DIR/cmds/index.sh"

# =============================================================================
#  SETUP ENVIRONMENT AND LOAD COMMON UTILITIES
# =============================================================================

# Setup environment variables
sdk_boo_env_setup_environment "$@"

# =============================================================================
# FINALIZE INITIALIZATION
# =============================================================================

# Set to context directory if available
if [ -d "$D_CTX_DIR" ]; then cd "$D_CTX_DIR"; fi

# Initialize debugger
# TODO this causes: /ctx/node_modules/@diseec/sdk/shared/utils.sh: line 65: pop_var_context: head of shell_variables not a function context
# because the script starts from host and then continues to container where the context is changed and then in case of error it tries to call pop_var_context and for some reason it fails
# sdk_boo_debug_init

# Add help command if no arguments provided
if [ $# -eq 0 ]; then set -- --help; fi
