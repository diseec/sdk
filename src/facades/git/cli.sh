#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

c=$1; shift; case $c in
    sta|status)
        cli_main inform forbid-dev-on-main
        cli_main inform summary-branch-status
        fac_git_cmd_pr_check_status
    ;;
    cpp|commit-push-pr) fac_git_cmd_commit_push_pr "$@" ;;
    che|checkout) fac_git_cmd_checkout_branch "$@" ;;
    com|commit) fac_git_cmd_commit "$@" ;;
    pul|pull) fac_git_cmd_pull_merge "$@" ;;
    pus|push) fac_git_cmd_push "$@" ;;
    pre|pull-request|pr) c=$1; shift; case $c in
        cre|create) fac_git_cmd_pr_create "$@" ;;
        sta|status) fac_git_cmd_pr_check_status "$@" ;;
    esac ;;
    log|log) fac_git_cmd_git_log "$@" ;;
    ida|insight-day) fac_git_cmd_daily_insight "$@" ;;
    rel|release) fac_git_cmd_release "$@" ;;
    cid|checkout-if-detached) fac_git_cmd_checkout_if_detached "$@" ;;
    hub) c=$1; shift; case $c in
        _) _gh "$@" ;;
        *)
            if [ ! -z $c ]; then message -e "Unknown command: '$c'"; fi
            # cli_main git hub help; exit 1;
        ;;
    esac ;;
    _) _git "$@" ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi 37 'Git Commands - AI-Powered Workflow Automation')" "" \
        "" "" "$(ansi 37 'Quick Actions')" "" \
        "    cpp|commit-push-pr   " "Auto-commit with AI ✨ message, push, and create/update PR" \
        "    sta|status           " "Check current branch PR status and unresolved comments" \
        "    pul|pull             " "Pull latest changes and merge with main branch" \
        "    com|commit           " "Commit changes with AI-generated message" \
        "    ida|insight-day      " "Generate daily insights" \
        "" "" "$(ansi 37 'Individual Operations')" "" \
        "    pre|pull-request     " "Create PR only (no commit/push)" \
        "    che|checkout         " "Checkout/create branch interactively" \
        "    hea|head             " "Get detailed commit report status, options: --recursive" \
        "    rel|release          " "Create release tag (development command)" \
        "" "" "$(ansi 37 'Direct Commands')" "" \
        "    _                    " "Direct git command passthrough" \
        "    hub _                " "Direct GitHub CLI command passthrough" \
        "" "" "$(ansi 37 'Aliases & Shortcuts')" "" \
        "    D push [--recursive]  " "Alias for commit-push-pr" \
        "    D pull [--recursive]  " "Alias for pull" \
        "" "" "$(ansi 33 'Setup Required')" "" \
        "    D secret add          " "Add OPENAI_API_KEY for AI commit messages" \
        "    gh auth login         " "Authenticate GitHub cli_main for PR management"
    ;;
    *)
        if [ ! -z $c ]; then message -e "Unknown command: '$c'"; fi
        cli_main git help; exit 1;
    ;;
esac
