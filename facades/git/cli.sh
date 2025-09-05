#!/bin/bash

source_once "$D_SDK_DIR/facades/git/index.sh"

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

c=$1; shift; case $c in
    sta|status)
        cli_main informs src_inf_forbid_dev_on_main
        cli_main informs src_inf_summary_branch_status
        src_fac_git_cmd_pr_check_status
    ;;
    cpp|commit-push-pr) src_fac_git_cmd_commit_push_pr "$@" ;;
    che|checkout) src_fac_git_cmd_checkout_branch "$@" ;;
    com|commit) src_fac_git_cmd_commit "$@" ;;
    pul|pull) src_fac_git_cmd_pull_merge "$@" ;;
    pus|push) src_fac_git_cmd_push "$@" ;;
    pre|pull-request|pr) c=$1; shift; case $c in
        cre|create) src_fac_git_cmd_pr_create "$@" ;;
        sta|status) src_fac_git_cmd_pr_check_status "$@" ;;
        *) if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi ;;
    esac; ;;
    log)
        TODAY_FLAG=0
        ARGS=""; for arg in "$@"; do case "$arg" in
            --today) src_fac_git_cmd_get_today_logs; TODAY_FLAG=1 ;;
        *) ARGS="$ARGS \"$arg\"";; esac; done
        if [ $TODAY_FLAG -eq 0 ]; then
            eval set -- $(eval echo $ARGS);
            src_fac_git_cmd_git_log "$@"
        fi
        ;;
    ida|insight-day) src_fac_git_cmd_daily_insight "$@" ;;
    rel|release) src_fac_git_cmd_release "$@" ;;
    cid|checkout-if-detached) src_fac_git_cmd_checkout_if_detached "$@" ;;
    hub) c=$1; shift; case $c in
        _) _gh "$@" ;;
        *)
            if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
            # cli_main git hub help; exit 1;
        ;;
    esac ;;
    _) _git "$@" ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi 97 'Git Commands - AI-Powered Workflow Automation')" "" \
        "" "" "$(ansi 97 'Quick Actions')" "" \
        "    cpp|commit-push-pr   " "Auto-commit with AI ✨ message, push, and create/update PR" \
        "    sta|status           " "Check current branch PR status and unresolved comments" \
        "    pul|pull             " "Pull latest changes and merge with main branch" \
        "    com|commit           " "Commit changes with AI-generated message" \
        "    ida|insight-day      " "Generate daily insights" \
        "" "" "$(ansi 97 'Individual Operations')" "" \
        "    pre|pull-request     " "Create PR only (no commit/push)" \
        "    che|checkout         " "Checkout/create branch interactively" \
        "    hea|head             " "Get detailed commit report status, options: --recursive" \
        "    rel|release          " "Create release tag (development command)" \
        "" "" "$(ansi 97 'Direct Commands')" "" \
        "    _                    " "Direct git command passthrough" \
        "    hub _                " "Direct GitHub CLI command passthrough" \
        "" "" "$(ansi 97 'Aliases & Shortcuts')" "" \
        "    $D_CLI_GLOBAL_NAME push [--recursive]  " "Alias for commit-push-pr" \
        "    $D_CLI_GLOBAL_NAME pull [--recursive]  " "Alias for pull" \
        "" "" "$(ansi 33 'Setup Required')" "" \
        "    $D_CLI_GLOBAL_NAME secret add          " "Add OPENAI_API_KEY for AI commit messages" \
        "    gh auth login         " "Authenticate GitHub cli_main for PR management"
    ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_main git help; exit 1;
    ;;
esac
