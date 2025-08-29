#!/bin/bash

fac_git_cmd_pull_merge() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    echo "$REPO_NAME: Pulling latest branch '$CURRENT_BRANCH' changes ..."
    _git -C "$ROOT_DIR" pull origin
    echo "$REPO_NAME: Merging latest 'origin/main' changes to branch '$CURRENT_BRANCH'..."
    _git -C "$ROOT_DIR" merge origin/main

    echo "$REPO_NAME: Pull and merge complete."

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Pull and merging in submodules..."
        pull_submodule() {
            local module="$1"
            local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D pull --recursive
        }
        fac_wor_foreach_selected_module pull_submodule
    fi
}
