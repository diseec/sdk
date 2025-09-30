#!/bin/bash

cli_ctx() {
    if [ -z "$D_CTX_DIR" ]; then
        stdout -e "calling cli_ctx in a undefined context. Cannot proceed."
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
        stdout -e --icon="E:OOC" "Command forbidden: '$D_INI_ARGS': Called in '$calling_function'() at $calling_file:$line_number"
        return 1
    fi
}

fix_permissions() {
    local target_dir="$1"

    if [ -z "$target_dir" ]; then
        stdout -e "No target directory provided to fix_permissions"
        return 1
    fi

    if [ ! -d "$target_dir" ] && [ ! -f "$target_dir" ] ; then
        stdout -e "Target does not exist: $target_dir"
        return 1
    fi

    if [ -z "$D_HOST_UID" ] || [ -z "$D_HOST_GID" ]; then
        stdout -e "D_HOST_UID or D_HOST_GID is not set. Cannot fix permissions."
        return 1
    fi
    
    # Check if target already has correct ownership
    local current_stat=$(stat -c "%u:%g" "$target_dir" 2>/dev/null)
    local expected_ownership="$D_HOST_UID:$D_HOST_GID"
    
    if [ "$current_stat" = "$expected_ownership" ]; then
        # Already has correct permissions, skip chown
        return 0
    fi
    
    stdout -d --processing "Fixing permissions for $target_dir to $D_HOST_UID:$D_HOST_GID"

    local fix_permissions_output=$(chown -R $D_HOST_UID:$D_HOST_GID "$target_dir")

    if [ $? -ne 0 ]; then
        stdout -e "Failed to fix permissions for $target_dir: $fix_permissions_output"
        return 1
    fi

    stdout -d "Fixed permissions for $target_dir to $D_HOST_UID:$D_HOST_GID"
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ HELP DISPLAY FUNCTION - Formatted Command List with Descriptions        ┃
# ┃ Provides a clean way to display commands and their descriptions in help ┃
# ┃ output                                                                  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

display_help() {
    # Loop through the arguments and print them
    while [ "$#" -gt 0 ]; do
        local command=$1
        local description=$2
        ansi 97 "$command"
        ansi 90 "$description"
        printf "\n"
        if [ "$#" -ge 2 ]; then shift 2
        else shift; fi
    done
    printf "\n"
}
