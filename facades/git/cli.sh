#!/bin/bash

source_once "$D_SDK_DIR/facades/git/index.sh"

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

c=$1; shift; case $c in
    sta|status)
        mark_ctx_only
        cli_ctx informs sdk_inf_forbid_dev_on_main
        cli_ctx informs sdk_inf_summary_branch_status
        sdk_fac_git_cmd_pr_check_status
        ;;
    clo|clone)
        echo $ctx_dir
        local ctx_dir="$(cli_ctx config function sdk_fac_con_get_suggest_ctx_dir "$1")"
        cli_ctx git _ clone https://$D_REPOSITORY_URL/"$1" "$ctx_dir"
        logit -l "Initializing recursively.., cloned into: $ctx_dir"
        cd "$ctx_dir"
        ("$D_CLI_GLOBAL_NAME" install --patch --recursive)
        ;;
    cpp|commit-push-pr) mark_ctx_only; sdk_fac_git_cmd_commit_push_pr "$@" ;;
    che|checkout) mark_ctx_only; sdk_fac_git_cmd_checkout_branch "$@" ;;
    com|commit) mark_ctx_only; sdk_fac_git_cmd_commit "$@" ;;
    pul|pull) mark_ctx_only; sdk_fac_git_cmd_pull_merge "$@" ;;
    pus|push) mark_ctx_only; sdk_fac_git_cmd_push "$@" ;;
    pre|pull-request|pr) mark_ctx_only; c=$1; shift; case $c in
        cre|create) sdk_fac_git_cmd_pr_create "$@" ;;
        sta|status) sdk_fac_git_cmd_pr_check_status "$@" ;;
        *) if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi ;;
    esac; ;;
    log)
        mark_ctx_only;
        TODAY_FLAG=0
        ARGS=""; for arg in "$@"; do case "$arg" in
            --today) sdk_fac_git_cmd_get_today_logs; TODAY_FLAG=1 ;;
        *) ARGS="$ARGS \"$arg\"";; esac; done
        if [ $TODAY_FLAG -eq 0 ]; then
            eval set -- $(eval echo $ARGS);
            sdk_fac_git_cmd_git_log "$@"
        fi
        ;;
    ida|insight-day) mark_ctx_only; sdk_fac_git_cmd_daily_insight "$@" ;;
    rel|release) mark_ctx_only; sdk_fac_git_cmd_release "$@" ;;
    cid|checkout-if-detached) mark_ctx_only; sdk_fac_git_cmd_checkout_if_detached "$@" ;;
    hub) c=$1; shift; case $c in
        _) _gh "$@" ;;
        *)
            if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
            # cli_ctx git hub help; exit 1;
        ;;
    esac ;;
    _) _git "$@" ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[$D_CLI_GLOBAL_NAME git]/[bash $D_CLI_LOCAL_NAME git] [command] [subcommand] [options]" \
        "                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$D_ORG_NAME/$D_SDK_NAME")")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Git Commands - AI-Powered Workflow Automation')")" "" \
        "" "" "$(ansi "1;90" "$(capitalize 'Quick Actions')")" "" \
        "    cpp|commit-push-pr   " "$(ansi 96 '✦') $(ansi 90 'Auto-commit with AI message, push, and create/update PR')" \
        "    sta|status           " "Check current branch PR status and unresolved comments" \
        "    clo|clone            " "Clone a repository and initialize recursively" \
        "    pul|pull             " "Pull latest changes and merge with main branch" \
        "    com|commit           " "Commit changes with AI-generated message" \
        "    ida|insight-day      " "$(ansi 36 '✦') $(ansi 90 'Generate daily insights')" \
        "" "" "$(ansi "1;90" "$(capitalize 'Individual Operations')")" "" \
        "    pre|pull-request     " "Create PR only (no commit/push)" \
        "        cre|create       " "$(ansi "2;90" "Create a new pull request")" \
        "        sta|status       " "$(ansi "2;90" "Check status of existing pull requests")" \
        "    che|checkout         " "Checkout/create branch interactively" \
        "    hea|head             " "Get detailed commit report status, options: --recursive" \
        "    rel|release          " "Create release tag (development command)" \
        "    log                  " "View commit history" \
        "        --today          " "$(ansi "2;90" "Show only today's commits")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Direct Commands')")" "" \
        "    _                    " "Direct git command passthrough" \
        "    hub _                " "Direct GitHub CLI command passthrough" \
        "" "" "$(ansi "1;90" "$(capitalize 'Aliases & Shortcuts')")" "" \
        "    $D_CLI_GLOBAL_NAME push [--recursive]  " "$(ansi 96 '✦') $(ansi 90 'Alias for commit-push-pr')" \
        "    $D_CLI_GLOBAL_NAME pull [--recursive]  " "Alias for pull" \
        "" "" "$(ansi "1;90" "$(capitalize 'Setup Required')")" "" \
        "    $D_CLI_GLOBAL_NAME secret add          " "Add OPENAI_API_KEY for AI commit messages" \
        "    gh auth login         " "Authenticate GitHub cli for PR management" \
        "$@"
    ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_ctx git help; exit 1;
    ;;
esac
