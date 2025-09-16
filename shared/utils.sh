#!/bin/bash

cli_ctx() {
    if [ -z "$D_CTX_DIR" ]; then
        stdout -e "calling cli_ctx in a undefined context. Cannot proceed." >&2
        return 1
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
            stdout -e "Error: Script not found: $script_path"
        fi
    else
        if [ "$#" -gt 0 ]; then
            stdout -w "Script already sourced, but arguments were provided and will be ignored: $script_path"
        fi
    fi
}

source_safely() {
    # Usage:
    # source_safely "./script.sh" "$@" ;;

    # Validate that first argument is a valid .sh script path
    if [ -z "$1" ]; then
        stdout -e "No script path provided to source_safely"
        return 1
    fi

    local script_path="$1"; shift
    
    if [[ ! "$script_path" == *cli.sh ]]; then
        stdout -e "Script path must end with cli.sh: $script_path"
        return 1
    fi

    # extract path part between command_root_name up to cli.sh (end of path) and join with spaces
    local path_based_cmd="${script_path#*facades/}";
    path_based_cmd="${path_based_cmd%/cli.sh}";
    path_based_cmd="${path_based_cmd//\// }"
    local full_cmd="$path_based_cmd $*"

    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        source "$script_path" "$@" # DO NOT use source_once here, the clean state variables need constant sourcing
    else
        cli_ctx --safely "$full_cmd";
    fi
}

mark_ctx_only() {
    # Mark the script to be allowed to only run when there is a project attached to the SDK context (i.e. D_CTX_DIR is set)
    if [ -z "${D_CTX_DIR:-}" ]; then
        # Get calling information
        local caller_info=$(caller 0)
        local line_number=$(echo "$caller_info" | cut -d ' ' -f 1)
        local calling_function=$(echo "$caller_info" | cut -d ' ' -f 2)
        local calling_file=$(echo "$caller_info" | cut -d ' ' -f 3-)
        stdout -e --icon="E:OOC" "Command forbidden: '$D_INI_ARGS': Called in '$calling_function'() at $calling_file:$line_number" >&2
        return 1
    fi
}