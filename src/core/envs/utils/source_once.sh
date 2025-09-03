#!/bin/bash

# Track sourced files
declare -A _SOURCED_FILES

source_once() {
    local script_path="$1"
    if [ -z "${_SOURCED_FILES[$script_path]}" ]; then
        if [ -f "$script_path" ]; then
            source "$script_path"
            _SOURCED_FILES[$script_path]=1
            return 0
        else
            echo "Error: Script not found: $script_path"
            return 1
        fi
    fi
}