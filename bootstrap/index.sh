#!/bin/bash

# =============================================================================
# PROCESS COMMAND-LINE ARGUMENTS
# =============================================================================

# Set log level if not already set
export D_LOG_LEVEL="${D_LOG_LEVEL:-DEBUG}" # change this to info when app stable

_ARGS_ENVS_PROCESS=""; for arg in "$@"; do case "$arg" in
    --log-level=*) D_LOG_LEVEL="${arg#*=}";;
    # --log-level*) D_LOG_LEVEL="${arg#--log-level }";;
    --debug) D_LOG_LEVEL="DEBUG" ;;
*) _ARGS_ENVS_PROCESS="$_ARGS_ENVS_PROCESS \"$arg\"";; esac; done; eval set -- $(eval echo $_ARGS_ENVS_PROCESS);

source "$D_SDK_DIR/bootstrap/environment/index.sh"

sdk_boo_env_setup_environment "$@"

# Load app wide common utilities
source "$D_SDK_DIR/shared/index.sh"

# Load bootstrap modules
source "$D_SDK_DIR/bootstrap/debug.sh"
source "$D_SDK_DIR/bootstrap/hooks.sh"

sdk_boo_debug_init
