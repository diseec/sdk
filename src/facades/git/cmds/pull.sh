#!/bin/bash

cmd_git_pull_merge() {
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
            "$ROOT_DIR/$module_path/cli" pull -r
        }
        foreach_selected_module_with_callback pull_submodule
    fi
}
