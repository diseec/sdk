#!/bin/bash

# =============================================================================
# PATH DISCOVERY UTILITIES
# =============================================================================
# Functions for discovering project structure and paths

con_uti_cli_auto_discovery() {
    # Canonicalize KIT_DIR
    kitdir=$(cd "$KIT_DIR" 2>/dev/null && pwd) || {
        echo "Error: can't access '$KIT_DIR'" >&2
        exit 1
    }
    
    # Exception: if the script's directory == KIT_DIR, return the first cli
    if [ "$IS_KIT_CLI" = "true" ]; then
        printf '%s\n' "$kitdir"
        return 0
    fi
    
    # if [ "$IS_IN_KIT_CONTAINER" = "true" ]; then # this breaks when a parent recursively do something on submodules then all of cli submodules point to the parent
    #     printf '%s\n' "/$PROJECT_MOUNT_DIR_NAME"
    #     return 0
    # fi
    
    # Start from the parent of KIT_DIR, as an absolute, canonical path
    start=$(cd "$kitdir/.." 2>/dev/null && pwd) || {
        echo "Error: can't access '$kitdir/..'" >&2
        exit 1
    }
    
    dir=$start
    while :; do
        if [ -f "$dir/cli" ]; then
            # Skip if it's the same file as $kitdir/cli
            if [ ! -e "$kitdir/cli" ] || [ ! "$dir/cli" -ef "$kitdir/cli" ]; then
                printf '%s\n' "$dir"
                return 0
            fi
        fi
        [ "$dir" = "/" ] && break
        dir=$(dirname -- "$dir")
    done
    
    echo "Error: cli not found, looked up all levels from: $kitdir" >&2
    exit 1
}

get_org_dir() {
    local org_dir="$HOME/$ORG_NAME"
    if [ ! -d "$org_dir" ]; then 
        mkdir -p "$org_dir"
    fi
    echo "$org_dir"
}

get_cache_dir() {
    local org_cache_dir="$(get_org_dir)/.cache"
    if [ ! -d "$org_cache_dir" ]; then 
        mkdir -p "$org_cache_dir"
    fi
    echo "$org_cache_dir"
}
