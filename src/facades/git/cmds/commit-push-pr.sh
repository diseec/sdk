#!/bin/bash

cmd_git_commit_push_pr() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    # _CLI_ inform check-internet-connection

    # _CLI_ git _checkout-if-detached
    # _CLI_ git pull

    # handle_hook before_cpp
    
    # # Only run commit if there are uncommitted changes
    # if [ -n "$(_git diff --staged)" ]; then
    #     _CLI_ git _commit
    # fi

    # _CLI_ git _push

    # if [ "$CURRENT_BRANCH" != "main" ]; then
    #     _CLI_ git pull-request
    # fi

    echo "$REPO_NAME: Cpp done."
    _CLI_ git _log "HEAD"

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            "$ROOT_DIR/$module_path/cli" git commit-push-pr --recursive
            echo "$REPO_NAME: Cpp done for submodule '$module'."
        }
        foreach_selected_module_with_callback cpp_submodule
    fi

    handle_hook after_cpp

    return 0
}