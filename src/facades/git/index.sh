#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

main() {
    . $KIT_SRC_DIR/facades/workspace/index.sh
    . $KIT_SRC_DIR/facades/git/exceptions.sh
    . $KIT_SRC_DIR/facades/git/utils.sh
    . $KIT_SRC_DIR/facades/git/cmds/commit-push-pr.sh
    . $KIT_SRC_DIR/facades/git/cmds/checkout.sh
    . $KIT_SRC_DIR/facades/git/cmds/commit.sh
    . $KIT_SRC_DIR/facades/git/cmds/pull.sh
    . $KIT_SRC_DIR/facades/git/cmds/push.sh
    . $KIT_SRC_DIR/facades/git/cmds/pr.sh
    . $KIT_SRC_DIR/facades/git/cmds/log.sh
    . $KIT_SRC_DIR/facades/git/cmds/release.sh

    c=$1; shift; case "$c" in
        sta|_status)
            . $CLI inform forbid-dev-on-main
            . $CLI inform _status-branch-status
            cmd_git_pr_check_status "$@"
        ;;
        cpp|_commit-push-pr) cmd_git_commit_push_pr "$@" ;;
        che|_checkout) cmd_git_checkout "$@" ;;
        com|_commit) cmd_git_commit "$@" ;;
        pul|_pull) cmd_git_pull "$@" ;;
        pus|_push) cmd_git_push "$@" ;;
        pre|_pull-request) cmd_git_pr "$@" ;;
        log|_log) cmd_git_log "$@" ;;
        rel|_release) cmd_git_release "$@" ;;
        hel|help|--help|-h) display_help "" "" \
            "$(color 30 'Git Commands - AI-Powered Workflow Automation')" "" \
            "" "" "$(color 30 'Quick Actions')" "" \
            "    cpp|_commit-push-pr   " "Auto-commit with AI ✨ message, push, and create/update PR" \
            "    sta|_status           " "Check current branch PR status and unresolved comments" \
            "    pul|_pull             " "Pull latest changes and merge with main branch" \
            "    com|_commit           " "Commit changes with AI-generated message" \
            "" "" "$(color 30 'Individual Operations')" "" \
            "    pre|_pull-request     " "Create PR only (no commit/push)" \
            "    che|_checkout         " "Checkout/create branch interactively" \
            "    hea|_head             " "Get detailed commit report _status, options: --recursive" \
            "    rel|_release          " "Create release tag (development command)" \
            "" "" "$(color 30 'Aliases & Shortcuts')" "" \
            "    D push [--recursive]  " "Alias for _commit-push-pr" \
            "    D pull [--recursive]  " "Alias for _pull" \
            "" "" "$(color 33 'Setup Required')" "" \
            "    D secret add          " "Add OPENAI_API_KEY for AI commit messages" \
            "    gh auth login         " "Authenticate GitHub CLI for PR management"
        ;;
        *) _git $c "$@" ;;
    esac
}

main "$@"
