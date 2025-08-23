#!/bin/bash

. $KIT_SRC_DIR/cmds/workspace/index.sh

set -e; cd $ROOT_DIR;

$CLI safe kit vise patch;
echo "$KIT_NAME version patched to: $VERSION"

ARGS=""; for arg in "$@"; do case "$arg" in
    --ignore-submodule-installation) IGNORE_SUBMODULE_INSTALLATION="true";;
*) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

git config --global credential.helper store

# Early return in CI environment - silent skip
[ -n "$CI" ] && { message 33 "CI" "Skipping interactive installation in CI environment"; return 0; }
# Early return if no submodules
[ "$HAS_SUBMODULES" != "true" ] && { return 0; }

if [ ! -f "$(get_workspace_config_path)" ]; then
    echo "$REPO_NAME: Initializing workspace configuration..."
    cmd_workspace_init
fi

echo "$REPO_NAME: Cloning selected submodules..."
initialize_submodule() {
    local module="$1"; local module_path="$2"
    echo "$REPO_NAME: Initializing submodule '$module'..."
    _git submodule update --init --recursive --remote "$module_path"
    echo "$REPO_NAME: Initialized submodule '$module'."
}
foreach_selected_module_with_callback initialize_submodule

echo "$REPO_NAME: Setting up branch tracking..."
GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
read -p "$(message 45 "?" "Branch to checkout: (press enter for '$GH_USERNAME')")" BRANCH
if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi
echo "$REPO_NAME: Checking out to branch '$BRANCH'..."
_git fetch && _git checkout $BRANCH || _git checkout -b $BRANCH origin/$BRANCH || _git checkout -b $BRANCH;
# message "Checking out branch '$BRANCH' in selected submodules..."
# checkout_branch() {
#     local module="$1"; local module_path="$2"; local branch="$3"
#     message 30 "$module" "Checking out branch..."
#     (cd "$ROOT_DIR/$module_path" && _git fetch && _git checkout $branch || _git checkout -b $branch origin/$branch || _git checkout -b $branch)
# }
# foreach_selected_module_with_callback checkout_branch "$BRANCH"

if [ "$IGNORE_SUBMODULE_INSTALLATION" != "true" ]; then
    echo "$REPO_NAME: Installing dependencies in selected submodules..."
    install_dependencies() {
        local module="$1"
        local module_path="$2"
        echo "$REPO_NAME: Installing dependencies for '$module'..."
        (cd "$ROOT_DIR/$module_path" && D install)
        echo "$REPO_NAME: Installed dependencies for '$module'."
    }
    foreach_selected_module_with_callback install_dependencies
fi

echo "$REPO_NAME: Workspace configuration initialized successfully."
message 32 "SUCCESS" "Installation completed successfully."
