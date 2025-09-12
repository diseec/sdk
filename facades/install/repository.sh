#!/bin/bash

sdk_fac_ins_repository() {
    set -e;

    logit -l "Installing ..."

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    cli_ctx install sdk;

    logit -l "$D_SDK_NAME version patched to: $D_VERSION"

    handle_hook before_install

    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { logit -w "Skipping interactive installation in CI environment"; return 0; }

    cli_ctx sdk start;

    _git config --global credential.helper store

    if [ ! -f "$(cli_ctx config path --scope=repository)" ] && [ "$D_HAS_SUBMODULES" = "true" ]; then
        logit -l "Initializing config configuration..."
        cli_ctx --safely config init
    fi

    cli_ctx git function sdk_fac_git_cmd_checkout_branch
    cli_ctx git function sdk_fac_git_cmd_checkout_if_detached

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Cloning selected submodules..."
        initialize_submodule() {
            local module="$1"; local module_path="$2"
            _git submodule update --init --recursive --remote "$module_path"
            logit -l "Initialized submodule '$module_path'."
        }
        cli_ctx config function sdk_fac_con_set_act_foreach_selected_module initialize_submodule
    fi

    cli_ctx sdk stop;

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Installing dependencies in selected submodules..."
        install_dependencies() {
            local module="$1"
            local module_path="$2"
            cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME --patch api v1 install.--recursive
            logit -l "Installed dependencies for '$module'."
        }
        cli_ctx config function sdk_fac_con_set_act_foreach_selected_module install_dependencies
    fi

    handle_hook after_install

    logit -o "Installation completed successfully."
}