#!/bin/bash

. $KIT_SRC_DIR/cmds/workspace.sh

get_version_specifier() {
    _node -p "require('$ROOT_DIR/package.json').dependencies?.['@$ORG_NAME/$KIT_NAME'] || require('$ROOT_DIR/package.json').devDependencies['@$ORG_NAME/$KIT_NAME']"
}

# Get the repository cache directory path
get_repo_cache_dir() {
    local repo_dir="$ORG_DIR/workspaces/$REPO_NAME"
    if [ ! -d "$repo_dir" ]; then
        mkdir -p "$repo_dir"
    fi
    
    # Create cache directory if it doesn't exist
    local cache_dir="$repo_dir/.cache"
    if [ ! -d "$cache_dir" ]; then
        mkdir -p "$cache_dir"
    fi
    
    echo "$cache_dir"
}

# Get the cached version of kit tools
get_cached_version() {
    local cache_file="$(get_repo_cache_dir)/kit_version.txt"
    
    if [ ! -f "$cache_file" ]; then
        # Return empty if no cache exists
        echo ""
        return 0
    fi
    
    # Return the cached version
    cat "$cache_file"
}

# Update the cached version of kit tools
set_cached_version() {
    local version="$1"
    local cache_file="$(get_repo_cache_dir)/kit_version.txt"
    
    # Clean version string by removing ^ ~ and other version range symbols
    local clean_version=$(echo "$version" | sed 's/[^~]//g')
    
    # Write the cleaned version to the cache file
    echo "$clean_version" > "$cache_file"
    
    message 34 "CACHE" "Updated cached $KIT_NAME version to: $clean_version"
}

# Check if kit version has changed
has_version_changed() {
    local cached_version=$(get_cached_version)
    
    # If no cached version, consider it changed
    if [ -z "$cached_version" ]; then
        return 0  # True
    fi
    
    # Clean the current version for comparison (remove ^ ~ and other version range symbols)
    local clean_current_version=$(echo "$(get_version_specifier)" | sed 's/[^~]//g')
    if [ "$clean_current_version" != "$cached_version" ] || [ "$clean_current_version" != "$VERSION" ]; then
        return 0  # True
    fi
    
    return 1  # False
}

cmd_update() {
    echo "Updating '$ROOT_DIR' with kit source '$KIT_DIR'..."
    set -e
    echo "On branch '$CURRENT_BRANCH' Pulling changes for '$REPO_NAME'..."
    _git pull origin
    $CLI safe kit vise patch;
    echo "$KIT_NAME version patched to: $VERSION"
    VERSION_SPECIFIER="$(get_version_specifier)"
    # Check if version has changed
    if has_version_changed; then
        local cached_version=$(get_cached_version)
        # Clean the version specifier for display and caching
        local clean_version_specifier=$(echo "$VERSION_SPECIFIER" | sed 's/[^~]//g')
        
        if [ -z "$cached_version" ]; then
            message 43 "SYNC" "First-time sync for $KIT_NAME version $clean_version_specifier"
        else
            message 43 "SYNC" "Version change: $cached_version -> $clean_version_specifier"
        fi

        $CLI event before_update

        message 44 "info" "Install and pulling latest $KIT_NAME image..."
        cd $KIT_DIR; $CLI kit docker compose pull;

        message 44 "info" "Installing dependencies..."
        $CLI install --ignore-submodule-installation;

        message 44 "info" "Pulling latest selected changes..."
        $CLI pull --ignore-submodule-pulling;

        update_dependencies() {
            local module="$1"
            local module_path="$2"
            echo "Updating dependencies for '$module'..."
            (cd "$ROOT_DIR/$module_path" && D update)
            echo "Updated dependencies for '$module'."
        }
        foreach_selected_module_with_callback update_dependencies
        
        $CLI event after_update

        # Update the cached version to current (cleaned version)
        local clean_version_specifier=$(echo "$VERSION_SPECIFIER" | sed 's/[^~]//g')
        set_cached_version "$clean_version_specifier"
        message 42 "OKEY" "Sync completed successfully for version $clean_version_specifier"
    else
        local clean_version_specifier=$(echo "$VERSION_SPECIFIER" | sed 's/[^~]//g')
        message 43 "SYNC" "Already synced to latest version $clean_version_specifier"
    fi
}
