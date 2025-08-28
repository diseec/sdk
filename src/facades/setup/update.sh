#!/bin/bash

SRC_KIT facades/workspace/index.sh

# Get version information for a package
get_version_info() {
    local package_name="@$ORG_NAME/$KIT_NAME"
    
    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)
    
    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        # Extract current and wanted versions using echo instead of stdin
        local current_version=$(echo "$outdated_json" | _node -pe "
            try { 
                const data = JSON.parse(require('fs').readFileSync(0, 'utf8')); 
                data['$package_name']?.current || '' 
            } catch(e) { '' }")
        local wanted_version=$(echo "$outdated_json" | _node -pe "
            try { 
                const data = JSON.parse(require('fs').readFileSync(0, 'utf8')); 
                data['$package_name']?.wanted || '' 
            } catch(e) { '' }")
        
        if [ -n "$current_version" ] && [ -n "$wanted_version" ]; then
            echo "$current_version -> $wanted_version"
        else
            echo ""
        fi
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
    set -e
    
    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    echo "Updating '$ROOT_DIR' with kit source '$KIT_DIR'..."
    echo "On branch '$CURRENT_BRANCH' Pulling changes for '$REPO_NAME'..."

    CLI git pull origin
    CLI kit docker compose pull;
    CLI safely kit do patch;
    echo "$KIT_NAME version patched to: $VERSION"

    # Check if version has changed
    fire_event before_update

    message 44 "info" "Installing dependencies..."
    CLI install;

    message 44 "info" "Pulling latest changes..."
    CLI pull;

    if [ "$HAS_SUBMODULES" = "true" ]; then
        echo "$REPO_NAME: Updating dependencies in selected submodules..."
        update_dependencies() {
            local module="$1"
            local module_path="$2"
            "$ROOT_DIR/$module_path/cli" update --recursive
            echo "Updated dependencies for '$module'."
        }
        CLI workspace foreach-selected-module-run update_dependencies
    fi

    fire_event after_update

    message 42 "OKEY" "Update completed successfully"
}

cmd_update "$@"