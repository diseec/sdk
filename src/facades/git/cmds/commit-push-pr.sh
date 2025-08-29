#!/bin/bash

fac_git_cmd_commit_push_pr() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    # cli_main inform check-internet-connection

    # cli_main git _checkout-if-detached
    # cli_main git pull

    # handle_hook before_cpp
    
    # # Only run commit if there are uncommitted changes
    # if [ -n "$(_git diff --staged)" ]; then
    #     cli_main git _commit
    # fi

    # cli_main git _push

    # if [ "$CURRENT_BRANCH" != "main" ]; then
    #     cli_main git pull-request
    # fi

    echo "$REPO_NAME: Cpp done."
    cli_main git _log "HEAD"

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            "$ROOT_DIR/$module_path/cli" git commit-push-pr --recursive
            echo "$REPO_NAME: Cpp done for submodule '$module'."
        }
        fac_wor_foreach_selected_module cpp_submodule
    fi

    handle_hook after_cpp

    return 0
}