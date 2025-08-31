#!/bin/bash

fac_set_project() {
    set -e;

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    cli_main safely kit do patch;
    echo "$KIT_NAME version patched to: $VERSION"

    handle_hook before_install

    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { message -w "Skipping interactive installation in CI environment"; return 0; }

    cli_main kit stop;
    cli_main kit start --detach;
    _git config --global credential.helper store

    if [ ! -f "$(cli_main workspace config path)" ] && [ "$HAS_SUBMODULES" = "true" ]; then
        echo "$REPO_NAME: Initializing workspace configuration..."
        cli_main workspace init
    fi

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Cloning selected submodules..."
        initialize_submodule() {
            local module="$1"; local module_path="$2"
            _git submodule update --init --recursive --remote "$module_path"
            echo "$REPO_NAME: Initialized submodule '$module_path'."
        }
        fac_wor_foreach_selected_module initialize_submodule
    fi

    cli_main git checkout-if-detached

    cli_main kit stop;

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Installing dependencies in selected submodules..."
        install_dependencies() {
            local module="$1"
            local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D install --recursive --patch
            echo "$REPO_NAME: Installed dependencies for '$module'."
        }
        fac_wor_foreach_selected_module install_dependencies
    fi

    handle_hook after_install

    echo "$REPO_NAME: Workspace configuration initialized successfully."
    message -o "Installation completed successfully."

}