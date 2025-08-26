#!/bin/bash

cmd_git_commit_push_pr() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    # . $CLI inform check-internet-connection

    # . "$CLI" git _checkout-if-detached
    # . "$CLI" git _pull

    # . "$CLI" event before_cpp
    
    # # Only run commit if there are uncommitted changes
    # if [ -n "$(_git diff --staged)" ]; then
    #     . "$CLI" git _commit
    # fi

    # . "$CLI" git _push

    # if [ "$CURRENT_BRANCH" != "main" ]; then
    #     . "$CLI" git _pull-request
    # fi

    echo "$REPO_NAME: Cpp done."
    . "$CLI" git _log "HEAD"

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            ("$ROOT_DIR/$module_path/cli" git _commit-push-pr --recursive)
            echo "$REPO_NAME: Cpp done for submodule '$module'."
        }
        "$CLI" workspace foreach-selected-module-run cpp_submodule
    fi

    "$CLI" event after_cpp

    return 0
}