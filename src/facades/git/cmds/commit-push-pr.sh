#!/bin/bash

cmd_git_commit_push_pr() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    # $CLI inform check-internet-connection

    # cmd_git_checkout_if_detached
    # cmd_git_pull_merge
    
    # $CLI event before_cpp
    
    # # Only run commit if there are uncommitted changes
    # if [ -n "$(_git diff --staged)" ]; then
    #     cmd_git_commit
    # fi

    # cmd_git_push

    # if [ "$CURRENT_BRANCH" != "main" ]; then
    #     cmd_git_pr_create
    # fi

    echo "$REPO_NAME: Cpp done."
    cmd_git_log "HEAD"

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            echo "$ROOT_DIR/$module_path/cli git _commit-push-pr"
            (cd "$ROOT_DIR/$module_path" && $ROOT_DIR/$module_path/cli git _commit-push-pr --recursive)
            echo "$REPO_NAME: Cpp done for submodule '$module'."
        }
        foreach_selected_module_with_callback cpp_submodule
    fi

    $CLI event after_cpp

    return 0
}