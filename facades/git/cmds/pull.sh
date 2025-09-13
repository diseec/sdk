#!/bin/bash

sdk_fac_git_cmd_pull_merge() {
    set -e

    logit -l "Pulling latest branch '$D_CURRENT_BRANCH' changes ..."
    _git -C "$D_CTX_DIR" pull origin
    logit -l "Merging latest 'origin/main' changes to branch '$D_CURRENT_BRANCH'..."
    _git -C "$D_CTX_DIR" merge origin/main

    logit -l "Pull and merge complete."

    if [ "$D_IS_RECURSIVE" = "true" ]; then
        logit -l "Pull and merging in submodules..."
        pull_submodule() {
            local module="$1"
            local module_path="$2"
            cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME api v1 pull.--recursive
        }
        cli_ctx submodule foreach_active pull_submodule
    fi
}
