#!/bin/bash

get_version_specifier() {
    $CLI $KIT_NAME exec $KIT_NAME --no-message node -p "require('$PROJECT_MOUNT_DIR/package.json').dependencies?.['@$ORG_NAME/$KIT_NAME'] || require('$PROJECT_MOUNT_DIR/package.json').devDependencies['@$ORG_NAME/$KIT_NAME']"
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

# Get the cached version of devops tools
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
    
    # Write the new version to the cache file
    echo "$version" > "$cache_file"
    
    message 34 "CACHE" "Updated cached $KIT_NAME version to: $version"
}

# Check if devops version has changed
has_version_changed() {
    local cached_version=$(get_cached_version)
    
    # If no cached version, consider it changed
    if [ -z "$cached_version" ]; then
        return 0  # True
    fi
    
    # Compare versions
    if [ "$VERSION" != "$cached_version" ] || [ "$VERSION" != "$(get_version_specifier)" ]; then
        return 0  # True
    fi
    
    return 1  # False
}

cmd_update() {
    set -e
    message 44 "info" "Pulling changes..."
    _git pull origin
    VERSION_SPECIFIER="$(get_version_specifier)"
    # Check if version has changed
    if has_version_changed; then
        local cached_version=$(get_cached_version)
        if [ -z "$cached_version" ]; then
            message 43 "SYNC" "First-time sync for $KIT_NAME version $VERSION"
        else
            message 43 "SYNC" "Version change: $cached_version -> $VERSION_SPECIFIER"
        fi

        $CLI event before_update

        message 44 "info" "Install and pulling latest $KIT_NAME image..."
        (cd $KIT_DIR; docker compose pull);
        $CLI $KIT_NAME exec $KIT_NAME /app/cli vise install;
        message 44 "info" "Installing dependencies..."
        $CLI install;
        message 44 "info" "Pulling latest selected changes..."
        $CLI pull;

        $CLI event after_update

        update_dependencies() {
            local module="$1"
            local module_path="$2"
            message 30 "$module" "Updating dependencies..."
            (cd "$ROOT_DIR/$module_path" && "$ROOT_DIR/$module_path/cli" update)
        }
        foreach_selected_module_with_callback update_dependencies
        
        # Update the cached version to current
        set_cached_version "$VERSION_SPECIFIER"
        message 42 "OKEY" "Sync completed successfully for version $VERSION_SPECIFIER"
    else
        message 43 "SYNC" "Already synced to latest version $VERSION_SPECIFIER"
    fi
}
