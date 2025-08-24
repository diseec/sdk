#!/bin/bash

. $KIT_SRC_DIR/cmds/workspace/index.sh
. $KIT_SRC_DIR/cmds/git/index.sh

set -e; cd $ROOT_DIR;

"$CLI" on-bench kit do patch;
echo "$KIT_NAME version patched to: $VERSION"

ARGS=""; for arg in "$@"; do case "$arg" in
    -r|--recursive) IS_RECURSIVE="true";;
*) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

git config --global credential.helper store

# Early return in CI environment - silent skip
[ -n "$CI" ] && { message 33 "CI" "Skipping interactive installation in CI environment"; return 0; }

if [ ! -f "$(get_workspace_config_path)" ]; then
    echo "$REPO_NAME: Initializing workspace configuration..."
    cmd_workspace_init
fi

if [ "$HAS_SUBMODULES" = "true" ]; then
    echo "$REPO_NAME: Cloning selected submodules..."
    initialize_submodule() {
        local module="$1"; local module_path="$2"
        _git submodule update --init --recursive --remote "$module_path"
        echo "$REPO_NAME: Initialized submodule '$module_path'."
    }
    foreach_selected_module_with_callback initialize_submodule
fi

cmd_git_checkout_if_detached

if [ "$IS_RECURSIVE" = "true" ]; then
    echo "$REPO_NAME: Installing dependencies in selected submodules..."
    install_dependencies() {
        local module="$1"
        local module_path="$2"
        (cd "$ROOT_DIR/$module_path" && D install --recursive)
        echo "$REPO_NAME: Installed dependencies for '$module'."
    }
    foreach_selected_module_with_callback install_dependencies
fi

echo "$REPO_NAME: Workspace configuration initialized successfully."
message 32 "SUCCESS" "Installation completed successfully."
