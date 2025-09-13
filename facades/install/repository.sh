#!/bin/bash

# npm link ./packages/sdk

sdk_fac_ins_rep_handle() {
    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { logit -w "Skipping interactive installation in CI environment"; return 0; }

    # cli_ctx sdk start;

    if [ -z "$(cli_ctx submodule actives)" ] && [ "$D_HAS_SUBMODULES" = "true" ]; then
        cli_ctx submodule select
    fi

    cli_ctx git _ config --global credential.helper store

    cli_ctx git function sdk_fac_git_cmd_checkout_branch
    cli_ctx git function sdk_fac_git_cmd_checkout_if_detached

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Cloning selected submodules..."
        initialize_submodule() {
            local module="$1"; local module_path="$2"
            _git submodule update --init --remote "$module_path"
            # _git submodule update --init --recursive --remote "$module_path"
            logit -l "Initialized submodule '$module_path'."
        }
        cli_ctx submodule foreach initialize_submodule
    fi

    # cli_ctx sdk stop;
}

sdk_fac_ins_repository() {
    set -e;

    logit -l "Installing ..."

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    handle_hook before_install

    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        sdk_fac_ins_rep_handle
    else
        cli_ctx --safely install function sdk_fac_ins_rep_handle;
    fi

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Installing dependencies in selected submodules..."
        install_dependencies() {
            local module="$1"
            local module_path="$2"
            (cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME --patch api v1 install.--recursive)
            logit -l "Installed dependencies for '$module'."
        }
        cli_ctx submodule foreach install_dependencies
    fi

    handle_hook after_install

    logit -o "Installation completed successfully."
}