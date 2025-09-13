#!/bin/bash

# npm link ./packages/sdk

# Function to create minimal docker-compose files for a submodule
create_minimal_compose_files() {
    local module="$1"
    local module_path="$2"
    
    local compose_file="$D_CTX_DIR/$module_path/docker-compose.yaml"
    local override_file="$D_CTX_DIR/$module_path/docker-compose.override.yaml"
    local root_compose="$D_CTX_DIR/docker-compose.yaml"
    local root_override="$D_CTX_DIR/docker-compose.override.yaml"
    
    # Check if the service is defined in the root docker-compose files
    local service_exists=false
    
    # Check in root docker-compose.yaml if it exists
    if [ -f "$root_compose" ]; then
        # Check for direct service definition
        if _yq '.services["'"$module"'"]' "$root_compose" 2>/dev/null | grep -v "null" &>/dev/null; then
            service_exists=true
        # Check for service with 'extends' pointing to this module
        elif _yq '.services[] | select(.extends.service == "'"$module"'")' "$root_compose" 2>/dev/null | grep -v "null" &>/dev/null; then
            service_exists=true
        # Check if the service name exists as a key in the services object (older yq syntax)
        elif _yq '.services | keys[] | select(. == "'"$module"'")' "$root_compose" 2>/dev/null | grep -q "$module" &>/dev/null; then
            service_exists=true
        fi
    fi
    
    # Check in root docker-compose.override.yaml if it exists
    if [ "$service_exists" = "false" ] && [ -f "$root_override" ]; then
        # Check for direct service definition
        if _yq '.services["'"$module"'"]' "$root_override" 2>/dev/null | grep -v "null" &>/dev/null; then
            service_exists=true
        # Check for service with 'extends' pointing to this module
        elif _yq '.services[] | select(.extends.service == "'"$module"'")' "$root_override" 2>/dev/null | grep -v "null" &>/dev/null; then
            service_exists=true
        # Check if the service name exists as a key in the services object (older yq syntax)
        elif _yq '.services | keys[] | select(. == "'"$module"'")' "$root_override" 2>/dev/null | grep -q "$module" &>/dev/null; then
            service_exists=true
        fi
    fi
    
    # Only create minimal compose files if the service exists in the root files
    if [ "$service_exists" = "true" ]; then
        # Create directory if it doesn't exist
        if [ ! -d "$D_CTX_DIR/$module_path" ]; then
            mkdir -p "$D_CTX_DIR/$module_path"
        fi
        
        if [ ! -f "$compose_file" ]; then
            cat > "$compose_file" << EOF
services:
  $module:
    profiles: []
EOF
        fi
        
        if [ ! -f "$override_file" ]; then
            cat > "$override_file" << EOF
services:
  $module:
    profiles: []
EOF
        fi
    fi
    
    return 0
}

# Function to check if a submodule directory is properly initialized (has .git)
check_clean_submodule() {
    local module="$1"
    local module_path="$2"
    local dir="$D_CTX_DIR/$module_path"
    
    # Check if directory exists but is not a proper git submodule
    if [ ! -d "$dir/.git" ] && [ ! -f "$dir/.git" ]; then
        if confirm "Submodule '$module_path' not a git repository, clean it up?"; then
            rm -rf "$dir"
        fi
    fi
    
    return 0
}

initialize_submodule() {
    local module="$1"; local module_path="$2"
    _git submodule update --init --remote "$module_path"
    local cmd_status=$?
    if [ $cmd_status -ne 0 ]; then
        logit -e "Failed to initialize submodule $module_path" >&2
        return $cmd_status
    fi
    logit -l "Initialized submodule '$module_path'."
    return 0
}

sdk_fac_ins_rep_handle() {
    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { logit -w "Skipping interactive installation in CI environment"; return 0; }

    local rep_failures=()
    local rep_exit_code=0

    # cli_ctx sdk start;

    cli_ctx git _ config --global credential.helper store
    if [ $? -ne 0 ]; then
        rep_failures+=("Git credential.helper store failed")
        rep_exit_code=1
    fi

    cli_ctx git function sdk_fac_git_cmd_checkout_branch
    if [ $? -ne 0 ]; then
        rep_failures+=("Git checkout branch failed")
        rep_exit_code=1
    fi

    cli_ctx git function sdk_fac_git_cmd_checkout_if_detached
    if [ $? -ne 0 ]; then
        rep_failures+=("Git common issues auto-fix failed")
        rep_exit_code=1
    fi

    if [ "$D_HAS_SUBMODULES" = "true" ]; then
        if [ -z "$(cli_ctx submodule actives)" ]; then
            cli_ctx submodule select
            if [ $? -ne 0 ]; then
                rep_failures+=("Submodule selection failed")
                rep_exit_code=1
            fi
        fi

        # Check and clean submodules before initialization
        cli_ctx submodule foreach check_clean_submodule
        if [ $? -ne 0 ]; then
            rep_failures+=("Submodule directory check failed")
            rep_exit_code=1
        fi

        if [ -n "$(cli_ctx submodule actives)" ]; then
            logit -l "Cloning selected submodules..."
            cli_ctx submodule foreach_active initialize_submodule
            if [ $? -ne 0 ]; then
                rep_failures+=("Submodule initialization failed")
                rep_exit_code=1
            fi
        fi

        # create docker-compose.override.yaml and docker-compose.yaml if not exist for all submodules defined
        cli_ctx submodule foreach create_minimal_compose_files
        if [ $? -ne 0 ]; then
            rep_failures+=("Creating minimal docker-compose files failed")
            rep_exit_code=1
        fi
    fi

    # cli_ctx sdk stop;

    # Report results
    if [ ${#rep_failures[@]} -ne 0 ]; then
        logit -w --ansi="31" "Repository handling finished with ${#rep_failures[@]} issues:"
        for failure in "${rep_failures[@]}"; do
            logit -e --icon="✖︎" "$failure"
        done
    fi
    return $rep_exit_code
}

sdk_fac_ins_repository() {
    # Store current errexit state
    local errexit_state=$(set -o | grep errexit | awk '{print $2}')
    
    # Force set -e off to track failures ourselves
    set +e
    
    # Initialize failure tracking
    local install_failures=()
    local exit_code=0

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    handle_hook before_install
    if [ $? -ne 0 ]; then
        install_failures+=("Before install hook failed")
        exit_code=1
    fi

    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        sdk_fac_ins_rep_handle
        if [ $? -ne 0 ]; then
            install_failures+=("Repository handling failed in SDK container")
            exit_code=1
        fi
    else
        cli_ctx --safely install function sdk_fac_ins_rep_handle
        if [ $? -ne 0 ]; then
            install_failures+=("Repository handling failed")
            exit_code=1
        fi
    fi

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Installing dependencies in selected submodules..."
        install_dependencies() {
            local module="$1"
            local module_path="$2"
            (cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME --patch api v1 install.--recursive)
            local cmd_status=$?
            if [ $cmd_status -ne 0 ]; then
                logit -e "Failed to install dependencies for $module" >&2
                return $cmd_status
            fi
            logit -l "Installed dependencies for '$module'."
            return 0
        }
        
        cli_ctx submodule foreach_active install_dependencies
        if [ $? -ne 0 ]; then
            install_failures+=("Submodule dependency installation failed")
            exit_code=1
        fi
    fi

    handle_hook after_install
    if [ $? -ne 0 ]; then
        install_failures+=("After install hook failed")
        exit_code=1
    fi
    
    # Report results
    if [ ${#install_failures[@]} -eq 0 ]; then
        logit -o "Installation completed successfully."
    else
        logit -w --ansi="31" "Installation completed with ${#install_failures[@]} issues:"
        for failure in "${install_failures[@]}"; do
            logit -e --icon="✖︎" "$failure"
        done
    fi
    
    # Restore previous errexit state
    if [ "$errexit_state" = "on" ]; then
        set -e
    fi
    
    return $exit_code
}