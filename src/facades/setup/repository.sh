#!/bin/bash

src_fac_set_repository() {
    set -e;

    logit -l "Installing ..."

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    cli_main safely kit act patch;
    logit -l "$KIT_NAME version patched to: $VERSION"

    handle_hook before_install

    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { logit -w "Skipping interactive installation in CI environment"; return 0; }

    cli_main kit start;

    _git config --global credential.helper store

    cli_main safely workspace init;
    if [ ! -f "$(cli_main workspace config path)" ] && [ "$HAS_SUBMODULES" = "true" ]; then
        logit -l "Initializing workspace configuration..."
        cli_main workspace function src_fac_wor_init
    fi

    cli_main git function src_fac_git_cmd_checkout_branch
    cli_main git function src_fac_git_cmd_checkout_if_detached

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Cloning selected submodules..."
        initialize_submodule() {
            local module="$1"; local module_path="$2"
            _git submodule update --init --recursive --remote "$module_path"
            logit -l "Initialized submodule '$module_path'."
        }
        cli_main workspace function src_fac_wor_foreach_selected_module initialize_submodule
    fi

    cli_main kit stop;

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Installing dependencies in selected submodules..."
        install_dependencies() {
            local module="$1"
            local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D --patch api v1 install.--recursive
            logit -l "Installed dependencies for '$module'."
        }
        cli_main workspace function src_fac_wor_foreach_selected_module install_dependencies
    fi

    handle_hook after_install

    logit -o "Installation completed successfully."
}