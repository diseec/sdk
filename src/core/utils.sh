#!/bin/bash

cli_main() {
    source "$CLI_MAIN" "$@"
}

cli_core() {
    source "$CLI_CORE" "$@"
}

# Track sourced files
_SOURCED_FILES=""
source_once() {
    local script_path="$1"
    shift
    # Check if path has been sourced by searching in space-delimited string
    if ! echo "$_SOURCED_FILES" | grep -q " $script_path "; then
        if [ -f "$script_path" ]; then
            source "$script_path" "$@"
            _SOURCED_FILES="$_SOURCED_FILES $script_path "
            return 0
        else
            echo "Error: Script not found: $script_path"
            return 1
        fi
    fi
}

safely() {
    # use this in cli case statement or anywhere be like:
    # cmd) safely && cmd "$@" ;;
k
    if [ "$IS_IN_KIT_CONTAINER" = "true" ]; then
        return 0
    elif [ "$IS_IN_CONTAINER" = "true" ]; then
        CONTAINER_ID=$(hostname 2>/dev/null || echo "unknown")
        logit -e "Trying to run '${ORIGINAL_ARGS[@]}' command in $KIT_NAME container, but already in a different container: $CONTAINER_ID" >&2
        exit 1
    else cli_main safely "${ORIGINAL_ARGS[@]}";
        return 1
    fi
}

source_safely() {
    # Usage:
    # source_safely "./script.sh" "$@" ;;

    if safely; then
        local script_path="$1"; shift
        
        # Validate that first argument is a valid .sh script path
        if [ -z "$script_path" ]; then
            logit -e "No script path provided to source_safely"
            return 1
        fi
        
        if [[ ! "$script_path" == *.sh ]]; then
            logit -e "Script path must end with .sh: $script_path"
            return 1
        fi
        
        source_once "$script_path" "$@"
    fi
}