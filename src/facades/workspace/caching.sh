#!/bin/bash
# Workspace Caching Functions
# Functions for managing cache directories in workspace

# Get the base cache directory for the workspace
# Usage: fac_wor_get_cache_dir
# Output: Path to the workspace cache directory
fac_wor_get_cache_dir() {
    local cache_dir="$ORG_DIR/workspaces/$REPO_NAME/.cache"
    
    # Create the cache directory if it doesn't exist
    if [ ! -d "$cache_dir" ]; then
        mkdir -p "$cache_dir"
    fi
    
    echo "$cache_dir"
}

# Get a specific cache subdirectory
# Usage: fac_wor_get_cache_subdir "subdir_name"
# Output: Path to the requested cache subdirectory
fac_wor_get_cache_subdir() {
    local subdir_name="$1"
    local base_cache_dir=$(fac_wor_get_cache_dir)
    local cache_subdir="$base_cache_dir/$subdir_name"
    
    # Create the subdirectory if it doesn't exist
    if [ ! -d "$cache_subdir" ]; then
        mkdir -p "$cache_subdir"
    fi
    
    echo "$cache_subdir"
}
