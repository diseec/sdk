#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

source "$KIT_SRC_DIR/facades/git/index.sh"

c=$1; shift; case "$c" in
    sta|status)
        cli_main inform forbid-dev-on-main
        cli_main inform status-branch-status
        fac_git_cmd_pr_check_status "$@"
    ;;
    cpp|commit-push-pr) fac_git_cmd_commit_push_pr "$@" ;;
    che|_checkout) fac_git_cmd_checkout_branch "$@" ;;
    com|_commit) fac_git_cmd_commit "$@" ;;
    pul|pull) fac_git_cmd_pull_merge "$@" ;;
    pus|_push) fac_git_cmd_push "$@" ;;
    pre|pull-request) fac_git_cmd_pr_create "$@" ;;
    log|_log) fac_git_cmd_git_log "$@" ;;
    rel|_release) fac_git_cmd_release "$@" ;;

    cid|_checkout-if-detached) fac_git_cmd_checkout_if_detached "$@" ;;

    hel|help|--help|-h) display_help "" "" \
        "$(color 30 'Git Commands - AI-Powered Workflow Automation')" "" \
        "" "" "$(color 30 'Quick Actions')" "" \
        "    cpp|commit-push-pr   " "Auto-commit with AI ✨ message, push, and create/update PR" \
        "    sta|status           " "Check current branch PR status and unresolved comments" \
        "    pul|pull             " "Pull latest changes and merge with main branch" \
        "    com|_commit           " "Commit changes with AI-generated message" \
        "" "" "$(color 30 'Individual Operations')" "" \
        "    pre|pull-request     " "Create PR only (no commit/push)" \
        "    che|_checkout         " "Checkout/create branch interactively" \
        "    hea|_head             " "Get detailed commit report status, options: --recursive" \
        "    rel|_release          " "Create release tag (development command)" \
        "" "" "$(color 30 'Aliases & Shortcuts')" "" \
        "    D push [--recursive]  " "Alias for commit-push-pr" \
        "    D pull [--recursive]  " "Alias for pull" \
        "" "" "$(color 33 'Setup Required')" "" \
        "    D secret add          " "Add OPENAI_API_KEY for AI commit messages" \
        "    gh auth login         " "Authenticate GitHub cli_main for PR management"
    ;;
    *) _git $c "$@" ;;
esac
