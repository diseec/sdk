#!/bin/bash

sdk_fac_git_cmd_commit_push_pr() {
    set -e

    cli_ctx informs sdk_fac_inf_check_internet_connection

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

    if [ "$D_GLOBAL_IS_RECURSIVE" = "true" ]; then
        stdout -l "Cpp for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            (cd "$D_CTX_DIR/$module_path" && $D_CLI_GLOBAL_NAME api v1 git.commit.push.pr)
            stdout -l "Cpp done for submodule '$module'."
        }
        cli_ctx submodule foreach_active cpp_submodule
    fi

    handle_hook after_push

    return 0
}