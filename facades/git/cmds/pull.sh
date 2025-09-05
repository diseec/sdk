#!/bin/bash

sdk_fac_git_cmd_pull_merge() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    logit -l "Pulling latest branch '$D_CURRENT_BRANCH' changes ..."
    _git -C "$D_CTX_DIR" pull origin
    logit -l "Merging latest 'origin/main' changes to branch '$D_CURRENT_BRANCH'..."
    _git -C "$D_CTX_DIR" merge origin/main

    logit -l "Pull and merge complete."

    if [ "$IS_RECURSIVE" = "true" ]; then
        logit -l "Pull and merging in submodules..."
        pull_submodule() {
            local module="$1"
            local module_path="$2"
            cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME api v1 pull.--recursive
        }
        cli_main config function sdk_fac_con_opt_act_foreach_selected_module pull_submodule
    fi
}
