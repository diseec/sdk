#!/bin/bash

# Get version information for a package
sdk_fac_ins_get_version_info() {
    local package_name="$D_SDK_NPM_PKG"

    # Get outdated info as JSON
    local outdated_json=$(_npm outdated "$package_name" --json 2>/dev/null)

    if [ -n "$outdated_json" ] && [ "$outdated_json" != "{}" ]; then
        # Debug the JSON structure
        local debug_output=$(echo "$outdated_json" | _jq -r 'keys')
        # logit -d "JSON keys: $debug_output"
        
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
    # Store current errexit state
    local errexit_state=$(set -o | grep errexit | awk '{print $2}')
    
    # Force set -e off to track failures ourselves
    set +e
    
    # Initialize failure tracking
    local update_failures=()
    local exit_code=0
    
    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    logit -i "Updating '$D_CTX_DIR' with sdk source '$D_SDK_DIR'..."
    logit -i "On branch '$D_CURRENT_BRANCH' Pulling changes for '$D_REPO_NAME'..."

    cli_ctx git _ pull origin
    if [ $? -ne 0 ]; then
        update_failures+=("Failed to pull from origin")
        exit_code=1
    fi

    handle_hook before_update
    if [ $? -ne 0 ]; then
        update_failures+=("Before update hook failed")
        exit_code=1
    fi

    cli_ctx install repository
    if [ $? -ne 0 ]; then
        update_failures+=("Repository installation failed")
        exit_code=1
    fi

    cli_ctx git function sdk_fac_git_cmd_pull_merge
    if [ $? -ne 0 ]; then
        update_failures+=("Git pull merge failed")
        exit_code=1
    fi

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Updating dependencies in selected submodules..."
        update_dependencies() {
            local module="$1"
            local module_path="$2"
            (cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME --patch api v1 update.--recursive)
            local cmd_status=$?
            if [ $cmd_status -ne 0 ]; then
                logit -e "Failed to update $module" >&2
                return $cmd_status
            fi
            logit -l "Updated dependencies for '$module'."
            return 0
        }
        
        cli_ctx submodule foreach update_dependencies
        if [ $? -ne 0 ]; then
            update_failures+=("Submodule updates failed")
            exit_code=1
        fi
    fi

    handle_hook after_update
    if [ $? -ne 0 ]; then
        update_failures+=("After update hook failed")
        exit_code=1
    fi
    
    # Report results
    if [ ${#update_failures[@]} -eq 0 ]; then
        logit -o "Update completed successfully"
    else
        logit -w "Update completed with ${#update_failures[@]} issues:"
        for failure in "${update_failures[@]}"; do
            logit -e "  - $failure"
        done
    fi
    
    # Restore previous errexit state
    if [ "$errexit_state" = "on" ]; then
        set -e
    fi
    
    return $exit_code
}