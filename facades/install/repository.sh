#!/bin/bash

# npm link ./packages/sdk

# todo: extract the error handling use a global var and show at the end of the process name it 'capture' (maybe)
# todo: develop a chain syntax `capture retry stdin` ?!

initialize_submodule() {
    local module="$1"; local module_path="$2"

    retry --manual "_git submodule sync"
    retry --manual --auto "_git submodule update --recursive --init --remote $module_path"
    local cmd_status=$?
    if [ $cmd_status -ne 0 ]; then
        stdout -e "Failed to initialize submodule $module_path" >&2
        return $cmd_status
    fi
    stdout -l "Initialized submodule '$module_path'."
    return 0
}

sdk_fac_ins_rep_handle() {
    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { stdout -w "Skipping interactive installation in CI environment"; return 0; }

    local rep_failures=()
    local rep_exit_code=0

    # cli_ctx sdk start;
    if [ -d "$D_CTX_DIR/.git" ]; then
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
    fi

    if [ "$D_HAS_SUBMODULES" = "true" ]; then
        if [ -z "$(cli_ctx --quiet submodule actives)" ]; then
            # Submodule selection
            retry "cli_ctx submodule select"
            if [ $? -ne 0 ]; then
                rep_failures+=("Submodule selection failed")
                rep_exit_code=1
            fi
        fi

        if [ -n "$(cli_ctx --quiet submodule actives)" ] && [ -d "$D_CTX_DIR/.git" ]; then
            stdout -l "Cloning selected submodules..."
            # cli_ctx submodule foreach_active initialize_submodule
            # if [ $? -ne 0 ]; then
            #     rep_failures+=("Submodule initialization failed")
            #     rep_exit_code=1
            # fi
            # stdout -l "Initialized submodule '$module_path'."
            retry --manual "_git submodule sync"
            retry --manual --auto "_git submodule update --recursive --init --remote"
            if [ $? -ne 0 ]; then
                stdout -e "Failed to initialize submodules" >&2
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
        stdout -w --ansi="31" "Repository handling finished with ${#rep_failures[@]} issues:"
        for failure in "${rep_failures[@]}"; do
            stdout -e --icon="✖︎" "$failure"
        done
    fi
    return $rep_exit_code
}

sdk_fac_ins_repository() {
    trap 'stdout -e "Interrupted by user (Ctrl+C). Exiting."; exit 130' INT

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

    cli_ctx --safely install function sdk_fac_ins_rep_handle
    if [ $? -ne 0 ]; then
        install_failures+=("Repository handling failed in SDK container")
        exit_code=1
    fi

    if [ "$D_GLOB_RECURSIVE" = "true" ]; then
        stdout -l "Installing dependencies in selected submodules..."
        local active_modules="$(cli_ctx --quiet submodule actives)"
        # Normalize whitespace: convert newlines/tabs to single spaces and trim edges
        active_modules=$(normalize $active_modules)
        # Now active_modules will be a single-line, space-separated list (or empty)
        for module_path in $active_modules; do
            if [ -d "$D_CTX_DIR/$module_path" ]; then
                stdout -l "Installing dependencies in $module_path..."
                retry "(cd \"$D_CTX_DIR/$module_path\" && $D_CLI_GLOBAL_NAME api v1 install)"
                if [ $? -ne 0 ]; then
                    install_failures+=("Dependency installation failed in submodule at $module_path")
                    exit_code=1
                else
                    stdout -l "Dependencies installed successfully in $module_path."
                fi
            else
                stdout -w "Submodule path '$module_path' does not exist or is not a directory."
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
        stdout -o "Installation completed successfully."
    else
        stdout -w --ansi="31" "Installation completed with ${#install_failures[@]} issues:"
        for failure in "${install_failures[@]}"; do
            stdout -e --icon="✖︎" "$failure"
        done
    fi
    
    # Restore previous errexit state
    if [ "$errexit_state" = "on" ]; then
        set -e
    fi
    
    return $exit_code
}