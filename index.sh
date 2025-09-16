#!/bin/bash

# =============================================================================
# PROCESS COMMAND-LINE ARGUMENTS
# =============================================================================

export D_GLOBAL_ENV="${D_GLOBAL_ENV:-DEVELOPMENT}" # Valid environments: DEVELOPMENT, TESTING, PRODUCTION
export D_GLOBAL_DEBUG="${D_GLOBAL_DEBUG:-false}"
export D_GLOBAL_LOG_LEVEL="${D_GLOBAL_LOG_LEVEL:-INFO}" # VERBOSE > INFO > WARNING > ERROR > QUIET
export D_GLOBAL_IS_RECURSIVE="${D_GLOBAL_IS_RECURSIVE:-false}"
export D_GLOBAL_TTY_AVAILABLE="${D_GLOBAL_TTY_AVAILABLE:-true}"  # TTY availability flag, true by default
export D_GLOBAL_SDK_PATCH_FORCE="${D_GLOBAL_SDK_PATCH_FORCE:-false}"

# Support both long and short options, including grouped short options
# Expand grouped short options (e.g., -rq -> -r -q)
_expanded_args=()
for arg in "$@"; do
    if [[ "$arg" =~ ^-[a-zA-Z]{2,}$ ]]; then
        # Split grouped options, e.g., -rq -> -r -q
        chars="${arg:1}"
        for ((i=0; i<${#chars}; i++)); do
            _expanded_args+=("-${chars:$i:1}")
        done
    else
        _expanded_args+=("$arg")
    fi
done
# Replace original args with expanded ones
_ARGS_ENVS_PROCESS=""; _found_command=false; for arg in "${_expanded_args[@]}"; do
    if [ "$_found_command" = true ]; then
        _ARGS_ENVS_PROCESS="$_ARGS_ENVS_PROCESS \"$arg\""
    else
        case "$arg" in
            -p|--patch)     D_GLOBAL_SDK_PATCH_FORCE="true" ;;
            -r|--recursive) D_GLOBAL_IS_RECURSIVE="true" ;;
            -d|--debug)     D_GLOBAL_DEBUG="true" ;;
            -q|--quiet)     D_GLOBAL_LOG_LEVEL="QUIET" ;;
            -v|--verbose)   D_GLOBAL_LOG_LEVEL="VERBOSE" ;;
            --log-level=*)  D_GLOBAL_LOG_LEVEL="${arg#*=}" ;;
            --env=*)        D_GLOBAL_ENV="${arg#*=}" ;;
            --no-tty)       D_GLOBAL_TTY_AVAILABLE="false" ;;
            *) _ARGS_ENVS_PROCESS="$_ARGS_ENVS_PROCESS \"$arg\""; _found_command=true;;
        esac
    fi
done; eval set -- $(eval echo $_ARGS_ENVS_PROCESS);

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
sdk_boo_debug_init

# Add help command if no arguments provided
if [ $# -eq 0 ]; then set -- --help; fi
