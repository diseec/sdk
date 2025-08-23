#!/bin/bash

. $KIT_SRC_DIR/cmds/workspace.sh

set -e; cd $ROOT_DIR; $CLI version;

ARGS=""; for arg in "$@"; do case "$arg" in
    --ignore-submodule-installation) IGNORE_SUBMODULE_INSTALLATION="true";;
*) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

git config --global credential.helper store

# Early return in CI environment - silent skip
[ -n "$CI" ] && { message 33 "CI" "Skipping interactive installation in CI environment"; return 0; }
# Early return if no submodules
[ "$HAS_SUBMODULES" != "true" ] && { return 0; }

if [ ! -f "$(get_workspace_config_path)" ]; then
    message 30 "WORKSPACE" "Initializing workspace configuration..."
    cmd_workspace_init
fi

echo "Cloning selected submodules..."
initialize_submodule() {
    local module="$1"; local module_path="$2"
    echo "Initializing submodule $module..."
    _git submodule update --init --recursive --remote "$module_path"
}
foreach_selected_module_with_callback initialize_submodule

echo "Setting up branch tracking..."
GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
read -p "$(message 45 "?" "Branch to checkout: (press enter for '$GH_USERNAME')")" BRANCH
if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi
echo "Checking out to branch '$BRANCH'..."
_git fetch && _git checkout $BRANCH || _git checkout -b $BRANCH origin/$BRANCH || _git checkout -b $BRANCH;
# message "Checking out branch '$BRANCH' in selected submodules..."
# checkout_branch() {
#     local module="$1"; local module_path="$2"; local branch="$3"
#     message 30 "$module" "Checking out branch..."
#     (cd "$ROOT_DIR/$module_path" && _git fetch && _git checkout $branch || _git checkout -b $branch origin/$branch || _git checkout -b $branch)
# }
# foreach_selected_module_with_callback checkout_branch "$BRANCH"

if [ "$IGNORE_SUBMODULE_INSTALLATION" != "true" ]; then
    echo "Installing dependencies in selected submodules..."
    install_dependencies() {
        local module="$1"
        local module_path="$2"
        echo "Installing dependencies for $module..."
        (cd "$ROOT_DIR/$module_path" && "$ROOT_DIR/$module_path/cli" install)
        echo "Installed dependencies for $module."
    }
    foreach_selected_module_with_callback install_dependencies
fi

message 32 "SUCCESS" "Workspace configuration initialized successfully."
