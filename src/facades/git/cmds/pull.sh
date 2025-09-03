#!/bin/bash

src_fac_git_cmd_pull_merge() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    logit -l "Pulling latest branch '$CURRENT_BRANCH' changes ..."
    _git -C "$ROOT_DIR" pull origin
    logit -l "Merging latest 'origin/main' changes to branch '$CURRENT_BRANCH'..."
    _git -C "$ROOT_DIR" merge origin/main

    logit -l "Pull and merge complete."

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Pull and merging in submodules..."
        pull_submodule() {
            local module="$1"
            local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D api v1 pull.--recursive
        }
        cli_main workspace function src_fac_wor_foreach_selected_module pull_submodule
    fi
}
