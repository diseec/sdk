#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

SRC_KIT facades/workspace/index.sh
# SRC_KIT facades/ai/index.sh

SRC_KIT facades/git/exceptions.sh
SRC_KIT facades/git/cmds/pull.sh
SRC_KIT facades/git/cmds/commit-push-pr.sh
SRC_KIT facades/git/cmds/checkout.sh
SRC_KIT facades/git/cmds/commit.sh
SRC_KIT facades/git/cmds/push.sh
SRC_KIT facades/git/cmds/pr.sh
SRC_KIT facades/git/cmds/log.sh
SRC_KIT facades/git/cmds/release.sh

c=$1; shift; case "$c" in
    sta|status)
        CLI inform forbid-dev-on-main
        CLI inform status-branch-status
        cmd_git_pr_check_status "$@"
    ;;
    cpp|commit-push-pr) cmd_git_commit_push_pr "$@" ;;
    che|_checkout) cmd_git_checkout_branch "$@" ;;
    com|_commit) cmd_git_commit "$@" ;;
    pul|pull) cmd_git_pull_merge "$@" ;;
    pus|_push) cmd_git_push "$@" ;;
    pre|pull-request) cmd_git_pr_create "$@" ;;
    log|_log) cmd_git_log "$@" ;;
    rel|_release) cmd_git_release "$@" ;;

    cid|_checkout-if-detached) cmd_git_checkout_if_detached "$@" ;;

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
        "    gh auth login         " "Authenticate GitHub CLI for PR management"
    ;;
    *) _git $c "$@" ;;
esac
