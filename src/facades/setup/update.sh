#!/bin/bash

# Get version information for a package
src_fac_set_get_version_info() {
    local package_name="$KIT_PACKAGE_NAME"
    
    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)

    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        # Debug the JSON structure
        local debug_output=$(echo "$outdated_json" | _jq -r 'keys')
        # logit -d "JSON keys: $debug_output"
        
        # Try to extract versions using different approaches since npm outdated format varies
        if echo "$outdated_json" | _jq -e '."@'$ORG_NAME'/'$KIT_NAME'" | has("current")' &>/dev/null; then
            # Object format with package name as key
            local current_version=$(echo "$outdated_json" | _jq -r '."@'$ORG_NAME'/'$KIT_NAME'".current // ""')
            local wanted_version=$(echo "$outdated_json" | _jq -r '."@'$ORG_NAME'/'$KIT_NAME'".wanted // ""')
        elif echo "$outdated_json" | _jq -e 'has(0)' &>/dev/null; then
            # Array format
            local current_version=$(echo "$outdated_json" | _jq -r '.[0].current // ""')
            local wanted_version=$(echo "$outdated_json" | _jq -r '.[0].wanted // ""')
        else
            # Try the most generic approach - find any current/wanted values
            local current_version=$(echo "$outdated_json" | _jq -r '.. | objects | .current? // empty' | head -1)
            local wanted_version=$(echo "$outdated_json" | _jq -r '.. | objects | .wanted? // empty' | head -1)
        fi
            
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
src_fac_set_has_version_changed() {
    local package_name="$KIT_PACKAGE_NAME"
    
    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)
    
    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        return 0  # Updates available
    else
        return 1  # No updates
    fi
}

src_fac_set_cmd_update() {
    set -e
    
    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    logit -l "Updating '$ROOT_DIR' with kit source '$KIT_DIR'..."
    logit -l "On branch '$CURRENT_BRANCH' Pulling changes for '$REPO_NAME'..."

    cli_main git _ pull origin
    cli_main kit docker compose _ pull
    cli_main safely kit act patch
    logit -l "$KIT_NAME version patched to: $VERSION"

    handle_hook before_update

    logit -i "Installing dependencies..."
    cli_main install

    logit -i "Pulling latest changes..."
    src_fac_git_cmd_pull_merge

    if [  "$IS_RECURSIVE" = "true"  ]; then
        logit -l "Updating dependencies in selected submodules..."
        update_dependencies() {
            local module="$1"
            local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D --patch api v1 update.--recursive
            logit -l "Updated dependencies for '$module'."
        }
        src_fac_wor_foreach_selected_module update_dependencies
    fi

    handle_hook after_update

    logit -o "Update completed successfully"
}