#!/bin/bash

sdk_fac_git_cmd_commit_push_pr() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    cli_ctx informs sdk_inf_check_internet_connection

    sdk_fac_git_cmd_checkout_if_detached
    sdk_fac_git_cmd_pull_merge

    handle_hook before_push
    
    sdk_fac_git_cmd_commit

    sdk_fac_git_cmd_push

    if [ "$D_CURRENT_BRANCH" != "main" ]; then
        sdk_fac_git_cmd_pr_create
    fi

    echo "$D_REPO_NAME: Cpp done."
    sdk_fac_git_cmd_git_log "HEAD"

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$D_REPO_NAME: Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME api v1 git.commit.push.pr.--recursive
            echo "$D_REPO_NAME: Cpp done for submodule '$module'."
        }
        cli_ctx config function sdk_fac_con_set_act_foreach_selected_module cpp_submodule
    fi

    handle_hook after_push

    return 0
}