#!/bin/bash

src_fac_git_cmd_commit_push_pr() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    cli_main informs src_inf_check_internet_connection

    src_fac_git_cmd_checkout_if_detached
    src_fac_git_cmd_pull_merge

    handle_hook before_push
    
    src_fac_git_cmd_commit

    src_fac_git_cmd_push

    if [ "$CURRENT_BRANCH" != "main" ]; then
        src_fac_git_cmd_pr_create
    fi

    echo "$REPO_NAME: Cpp done."
    src_fac_git_cmd_git_log "HEAD"

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            cd "$ROOT_DIR/$module_path" && D api v1 git.commit.push.pr.--recursive
            echo "$REPO_NAME: Cpp done for submodule '$module'."
        }
        cli_main workspace function src_fac_wor_foreach_selected_module cpp_submodule
    fi

    handle_hook after_push

    return 0
}