#!/bin/bash

cli_ctx() {
    if [ -z "$D_CTX_DIR" ]; then
        logit -e "calling cli_ctx in a undefined context. Cannot proceed." >&2
        exit 1
    fi
    source "$D_CLI_STUB" "$@"
}

cli_core() {
    source "$D_CLI_CORE" "$@"
}

# Track sourced files
_SOURCED_FILES=""
source_once() {
    local script_path="$1"
    shift
    # Check if path has been sourced by searching in space-delimited string
    if ! echo "$_SOURCED_FILES" | grep -q " $script_path "; then
        if [ -f "$script_path" ]; then
            _SOURCED_FILES="$_SOURCED_FILES $script_path "
            source "$script_path" "$@" # Watch out the exit status
        else
            logit -e "Error: Script not found: $script_path"
        fi
    else
        if [ "$#" -gt 0 ]; then
            logit -w "Script already sourced, but arguments were provided and will be ignored: $script_path"
        fi
    fi
}

safely() {
    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        "$@" # Watch out the exit status
    elif [ "$D_IS_IN_CONTAINER" = "true" ]; then
        CONTAINER_ID=$(hostname 2>/dev/null || echo "unknown")
        logit -e "Trying to run '${D_INI_ARGS[@]}' command in '$D_SDK_NAME' container, but already in a different container: $CONTAINER_ID" >&2
        exit 1
    else
        cli_ctx --safely "${D_INI_ARGS[@]}";
    fi
}

source_safely() {
    # Usage:
    # source_safely "./script.sh" "$@" ;;
    process_source_safely() {
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
        source "$script_path" "$@" # DO NOT use source_once here, the clean state variables need constant sourcing
    }

    safely process_source_safely "$@"
}

mark_ctx_only() {
    # Mark the script to be allowed to only run when there is a project attached to the SDK context (i.e. D_CTX_DIR is set)
    if [ -z "${D_CTX_DIR:-}" ]; then
        # Get calling information
        local caller_info=$(caller 0)
        local line_number=$(echo "$caller_info" | cut -d ' ' -f 1)
        local calling_function=$(echo "$caller_info" | cut -d ' ' -f 2)
        local calling_file=$(echo "$caller_info" | cut -d ' ' -f 3-)
        logit -e --icon="E:OOC" "Command forbidden: '$D_INI_ARGS': Called in '$calling_function'() at $calling_file:$line_number" >&2
        exit 1
    fi
}