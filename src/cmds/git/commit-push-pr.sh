#!/bin/bash

cmd_git_commit_push_pr() {
    set -e

    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    $CLI inform check-internet-connection

    cmd_git_checkout_if_detached
    cmd_git_pull_merge
    
    $CLI event before_push

    # Check if there are any changes to commit or push
    local has_uncommitted_changes=false
    local has_unpushed_commits=false
    
    # Check for uncommitted changes (including untracked files)
    if [ -n "$(_git status --porcelain)" ]; then
        has_uncommitted_changes=true
    fi
    
    # Check for unpushed commits
    local unpushed_commits=$(_git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed_commits" -gt 0 ]; then
        has_unpushed_commits=true
    fi
    
    # If nothing to commit or push, return error
    if [ "$has_uncommitted_changes" = false ] && [ "$has_unpushed_commits" = false ]; then
        message 31 "ERROR" "Nothing to commit or push. Repository is already up to date."
        return 1
    fi
    
    # Only run commit if there are uncommitted changes
    if [ "$has_uncommitted_changes" = true ]; then
        cmd_git_commit
    fi
    
    # Always run push and PR creation if we got this far
    cmd_git_push
    cmd_git_pr_create

    if [ "$IS_RECURSIVE" = "true" ]; then
        echo "$REPO_NAME: Commit, push and creating PR for selected submodules..."
        cpp_submodule() {
            local module="$1"; local module_path="$2"
            (cd "$ROOT_DIR/$module_path" && D git _commit-push-pr --recursive)
            echo "$REPO_NAME: Commit, push and creating PR done for submodule '$module'."
        }
        foreach_selected_module_with_callback cpp_submodule
    fi

    $CLI event after_push

    return 0
}