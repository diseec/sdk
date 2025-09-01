#!/bin/bash

fac_set_project() {
    set -e;

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    cli_main safely kit act patch;
    logger -l "$KIT_NAME version patched to: $VERSION"

    handle_hook before_install

    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { logger -w "Skipping interactive installation in CI environment"; return 0; }

    cli_main kit start;

    _git config --global credential.helper store

    if [ ! -f "$(cli_main workspace config path)" ] && [ "$HAS_SUBMODULES" = "true" ]; then
        logger -l "Initializing workspace configuration..."
        cli_main workspace init
    fi

    if [ "$IS_RECURSIVE" = "true" ]; then
        logger -l "Cloning selected submodules..."
        initialize_submodule() {
            local module="$1"; local module_path="$2"
            _git submodule update --init --recursive --remote "$module_path"
            logger -l "Initialized submodule '$module_path'."
        }
        fac_wor_foreach_selected_module initialize_submodule
    fi

    cli_main git checkout
    cli_main git checkout-if-detached

    cli_main kit stop;

    if [ "$IS_RECURSIVE" = "true" ]; then
        logger -l "Installing dependencies in selected submodules..."
        install_dependencies() {
            local module="$1"
            local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D install --recursive --patch
            logger -l "Installed dependencies for '$module'."
        }
        fac_wor_foreach_selected_module install_dependencies
    fi

    handle_hook after_install

    logger -o "Installation completed successfully."
}