#!/bin/bash

. $KIT_SRC_DIR/cmds/workspace.sh

# Get version information for a package
get_version_info() {
    local package_name="@$ORG_NAME/$KIT_NAME"
    
    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)
    
    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        # Extract current and wanted versions
        local current_version=$(echo "$outdated_json" | _node -pe "JSON.parse(process.stdin.read())['$package_name']?.current || ''")
        local wanted_version=$(echo "$outdated_json" | _node -pe "JSON.parse(process.stdin.read())['$package_name']?.wanted || ''")
        
        echo "$current_version -> $wanted_version"
    else
        echo ""
    fi
}

# Check if kit version has changed
has_version_changed() {
    local package_name="@$ORG_NAME/$KIT_NAME"
    
    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)
    
    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        return 0  # Updates available
    else
        return 1  # No updates
    fi
}

cmd_update() {
    echo "Updating '$ROOT_DIR' with kit source '$KIT_DIR'..."
    set -e
    echo "On branch '$CURRENT_BRANCH' Pulling changes for '$REPO_NAME'..."
    _git pull origin
    $CLI safe kit vise patch;
    echo "$KIT_NAME version patched to: $VERSION"

    # Check if version has changed
    if has_version_changed; then
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

        message 42 "OKEY" "Sync completed successfully"
    else
        message 43 "SYNC" "Already up to date"
    fi
}
