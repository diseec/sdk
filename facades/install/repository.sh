#!/bin/bash

# npm link ./packages/sdk

# todo: extract the error handling use a global var and show at the end of the process name it 'capture' (maybe)
# todo: develop a chain syntax `capture retry input` ?!

initialize_submodule() {
    local module="$1"; local module_path="$2"
    
    retry --manual --auto "_git submodule update --init --remote \"$module_path\""
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

    # Git credential helper setup
    retry "cli_ctx git _ config --global credential.helper store"
    if [ $? -ne 0 ]; then
        rep_failures+=("Git credential.helper store failed")
        rep_exit_code=1
    fi

    # Git branch checkout
    retry "cli_ctx git function sdk_fac_git_cmd_checkout_branch"
    if [ $? -ne 0 ]; then
        rep_failures+=("Git checkout branch failed")
        rep_exit_code=1
    fi

    # Fix detached HEAD
    retry "cli_ctx git function sdk_fac_git_cmd_checkout_if_detached"
    if [ $? -ne 0 ]; then
        rep_failures+=("Git common issues auto-fix failed")
        rep_exit_code=1
    fi

    if [ "$D_HAS_SUBMODULES" = "true" ]; then
        if [ -z "$(cli_ctx submodule actives --quiet)" ]; then
            # Submodule selection
            retry "cli_ctx submodule select"
            if [ $? -ne 0 ]; then
                rep_failures+=("Submodule selection failed")
                rep_exit_code=1
            fi
        fi

        if [ -n "$(cli_ctx submodule actives --quiet)" ]; then
            logit -l "Cloning selected submodules..."
            cli_ctx submodule foreach_active initialize_submodule
            if [ $? -ne 0 ]; then
                rep_failures+=("Submodule initialization failed")
                rep_exit_code=1
            fi
        fi
    fi

    retry "cli_ctx docker function sdk_doc_init_compose_files"
    if [ $? -ne 0 ]; then
        rep_failures+=("Docker compose file initialization failed")
        rep_exit_code=1
    fi
    
    _compose_files_init () {
        local module="$1"
        local module_path="$2"
        retry "cli_ctx docker function sdk_doc_init_compose_files \"$D_CTX_DIR/$module_path\""
        return $?
    }
    cli_ctx submodule foreach_active _compose_files_init
    if [ $? -ne 0 ]; then
        rep_failures+=("Docker compose file initialization in submodules failed")
        rep_exit_code=1
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

    retry "handle_hook before_install"
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


    if [ "$D_IS_RECURSIVE" = "true" ]; then
        logit -l "Installing dependencies in selected submodules..."
        local active_modules="$(cli_ctx submodule actives --quiet)" # sample output: "path/to/module_1 path/to/module_2"
        for module_path in $active_modules; do
            if [ -d "$D_CTX_DIR/$module_path" ]; then
                logit -l "Installing dependencies in $module_path..."
                retry "(cd \"$D_CTX_DIR/$module_path\" && $D_CLI_GLOBAL_NAME --patch api v1 install.--recursive)"
                if [ $? -ne 0 ]; then
                    install_failures+=("Dependency installation failed in submodule at $module_path")
                    exit_code=1
                else
                    logit -l "Dependencies installed successfully in $module_path."
                fi
            else
                logit -w "Submodule path '$module_path' does not exist or is not a directory."
                install_failures+=("Submodule path '$module_path' invalid")
                exit_code=1
            fi
        done


        if [ $? -ne 0 ]; then
            install_failures+=("Submodule dependency installation failed")
            exit_code=1
        fi
    fi

    retry "handle_hook after_install"
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