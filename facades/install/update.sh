#!/bin/bash

# Get version information for a package
sdk_fac_ins_get_version_info() {
    local package_name="$D_SDK_NPM_PKG"

    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)

    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        # Debug the JSON structure
        local debug_output=$(echo "$outdated_json" | _jq -r 'keys')
        # stdout -d "JSON keys: $debug_output"
        
        # Try to extract versions using different approaches since npm outdated format varies
        if echo "$outdated_json" | _jq -e '."@'$D_ORG_NAME'/'$D_SDK_NAME'" | has("current")' &>/dev/null; then
            # Object format with package name as key
            local current_version=$(echo "$outdated_json" | _jq -r '."@'$D_ORG_NAME'/'$D_SDK_NAME'".current // ""')
            local wanted_version=$(echo "$outdated_json" | _jq -r '."@'$D_ORG_NAME'/'$D_SDK_NAME'".wanted // ""')
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

# Check if sdk version has changed
sdk_fac_ins_has_version_changed() {
    local package_name="$D_SDK_NPM_PKG"
    
    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)
    
    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        return 0  # Updates available
    else
        return 1  # No updates
    fi
}

sdk_fac_ins_cmd_update() {
    trap 'stdout -e "Interrupted by user (Ctrl+C). Exiting."; exit 130' INT
    
    # Store current errexit state
    local errexit_state=$(set -o | grep errexit | awk '{print $2}')
    
    # Force set -e off to track failures ourselves
    set +e
    
    # Initialize failure tracking
    local update_failures=()
    local exit_code=0
    
    stdout -i "Updating '$D_CTX_DIR' with sdk source '$D_SDK_DIR'..."
    stdout -i "On branch '$D_CURRENT_BRANCH' Pulling changes for '$D_REPO_NAME'..."

    retry --manual --auto "cli_ctx git _ pull origin"
    if [ $? -ne 0 ]; then
        update_failures+=("Failed to pull from origin")
        exit_code=1
    fi

    retry "handle_hook before_update"
    if [ $? -ne 0 ]; then
        update_failures+=("Before update hook failed")
        exit_code=1
    fi

    cli_ctx install repository
    if [ $? -ne 0 ]; then
        update_failures+=("Repository installation failed")
        exit_code=1
    fi

    retry --manual --auto "cli_ctx git function sdk_fac_git_cmd_pull_merge"
    if [ $? -ne 0 ]; then
        update_failures+=("Git pull merge failed")
        exit_code=1
    fi

    if [ "$D_GLOBAL_IS_RECURSIVE" = "true" ]; then
        stdout -l "Updating dependencies in selected submodules..."
        local active_modules="$(cli_ctx --quiet submodule actives)" # sample output: "path/to/module_1 path/to/module_2"
        for module_path in $active_modules; do
            if [ -d "$D_CTX_DIR/$module_path" ]; then
                stdout -l "Updating dependencies in $module_path..."
                retry "(cd \"$D_CTX_DIR/$module_path\" && $D_CLI_GLOBAL_NAME api v1 update)"
                if [ $? -ne 0 ]; then
                    install_failures+=("Dependency update failed in submodule at $module_path")
                    exit_code=1
                else
                    stdout -l "Dependencies updated successfully in $module_path."
                fi
            else
                stdout -w "Submodule path '$module_path' does not exist or is not a directory."
                install_failures+=("Submodule path '$module_path' invalid (update)")
                exit_code=1
            fi
        done


        if [ $? -ne 0 ]; then
            install_failures+=("Submodule dependency installation failed")
            exit_code=1
        fi
    fi

    retry "handle_hook after_update"
    if [ $? -ne 0 ]; then
        update_failures+=("After update hook failed")
        exit_code=1
    fi
    
    # Report results
    if [ ${#update_failures[@]} -eq 0 ]; then
        stdout -o "Update completed successfully"
    else
        stdout -w --ansi="31" "Update completed with ${#update_failures[@]} issues:"
        for failure in "${update_failures[@]}"; do
            stdout -e --icon="✖︎" "$failure"
        done
    fi
    
    # Restore previous errexit state
    if [ "$errexit_state" = "on" ]; then
        set -e
    fi
    
    return $exit_code
}