#!/bin/bash

# Get version information for a package
fac_set_get_version_info() {
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
fac_set_has_version_changed() {
    local package_name="@$ORG_NAME/$KIT_NAME"
    
    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)
    
    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        return 0  # Updates available
    else
        return 1  # No updates
    fi
}

fac_set_cmd_update() {
    set -e
    
    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    echo "Updating '$ROOT_DIR' with kit source '$KIT_DIR'..."
    echo "On branch '$CURRENT_BRANCH' Pulling changes for '$REPO_NAME'..."

    cli_main git pull origin
    cli_main kit docker compose pull
    cli_main safely kit do patch
    echo "$KIT_NAME version patched to: $VERSION"

    handle_hook before_update

    message -i "Installing dependencies..."
    cli_main install

    message -i "Pulling latest changes..."
    cli_main pull

    if [  "$IS_RECURSIVE" = "true"  ]; then
        echo "$REPO_NAME: Updating dependencies in selected submodules..."
        update_dependencies() {
            local module="$1"
            local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D update --recursive --force-patch
            echo "Updated dependencies for '$module'."
        }
        fac_wor_foreach_selected_module update_dependencies
    fi

    handle_hook after_update

    message -o "Update completed successfully"
}