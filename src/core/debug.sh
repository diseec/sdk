#!/bin/bash

X() {
    # if [[ "$DEBUG" == "true" ]]; then
    # set -x  # Print commands before execution
    # fi
    # local level="$1"
    # local message="$2"
  
    local file="${BASH_SOURCE[1]##*/}"
    local line="${BASH_LINENO[0]}"
    
    if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
            # Set local trap just for this function
            trap 'logit -e "'["$@"]' (${BASH_SOURCE[0]}:${LINENO}): ${BASH_COMMAND}"' ERR
            # Optionally log entry to function
            logit -d "[$file:$line]: $@"
    fi
}

function src_cor_debug_init() {
    # Only set these options if debug mode is enabled
    if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
        # Enable command tracing if extra verbose is needed
        if [[ "${TRACE}" == "true" ]]; then
            set -x
        fi
        # Global error trap that provides detailed context
        trap 'logit -e "[GLOBAL TRAP] ${FUNCNAME[0]:-main} (${BASH_SOURCE[0]}:${LINENO}): ${BASH_COMMAND}"' ERR
    fi
    # Always exit on error for consistency
    set -e
    # Prevent undefined variables from being used
    set -u
    # Uncomment if you want pipeline failures to be caught
    # set -o pipefail
}
