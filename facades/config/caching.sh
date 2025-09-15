#!/bin/bash
# Base Caching Functions
# Functions for managing cache directories based on scope

# Get the base cache directory
# Usage: sdk_fac_con_get_cache_dir <scope>
# Output: Path to the <scope> cache directory
sdk_fac_con_get_cache_dir() {
    local scope="$1"
    local cache_dir=""
    
    case "$scope" in
        context) cache_dir="$CACHE_CTX_DIR" ;;
        repository) cache_dir="$CACHE_REPO_DIR" ;;
        user) cache_dir="$CACHE_USER_DIR" ;;
        *) stdout -e "Invalid cache scope: $scope" ; return 1 ;;
    esac


    # Create the cache directory if it doesn't exist
    if [ ! -d "$cache_dir" ]; then
        mkdir -p "$cache_dir"
    fi
    
    echo "$cache_dir"
}

# Get a specific cache subdirectory
# Usage: sdk_fac_con_get_cache_subdir "<scope>" "subdir_name"
# Output: Path to the requested cache subdirectory
sdk_fac_con_get_cache_subdir() {
    local scope="$1"
    local subdir_name="$2"
    local base_cache_dir=$(sdk_fac_con_get_cache_dir "$scope")
    local cache_subdir="$base_cache_dir/$subdir_name"
    
    # Create the subdirectory if it doesn't exist
    if [ ! -d "$cache_subdir" ]; then
        mkdir -p "$cache_subdir"
    fi
    
    echo "$cache_subdir"
}
