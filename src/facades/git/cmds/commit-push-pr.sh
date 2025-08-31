#!/bin/bash

fac_git_cmd_commit_push_pr() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    cli_main inform check-internet-connection

    cli_main git checkout-if-detached
    cli_main git pull

    handle_hook before_push
    
    cli_main git commit

    cli_main git push

    if [ "$CURRENT_BRANCH" != "main" ]; then
        cli_main git pull-request
    fi

    echo "$REPO_NAME: Cpp done."
    cli_main git log "HEAD"

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D git commit-push-pr --recursive
            echo "$REPO_NAME: Cpp done for submodule '$module'."
        }
        fac_wor_foreach_selected_module cpp_submodule
    fi

    handle_hook after_push

    return 0
}