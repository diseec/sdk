#!/bin/sh

c=$1; shift; case $c in

    ######################## PROJECT MANAGEMENT ########################

    sys|system) . $KIT_SRC_DIR/cmds/install/system.sh "$@" ;;
    ins|install) . $KIT_SRC_DIR/cmds/install/project.sh "$@" ;;
    ude|update) . $KIT_SRC_DIR/cmds/update.sh; cmd_update "$@" ;;
    sta|status)         
        . $CLI version
        . $CLI workspace status
        . $CLI inform check-system-dependencies
        . $CLI inform check-internet-connection
        . $CLI git _status
        . $CLI inform check-for-updates
    ;;

    ######################## DEVELOPMENT ENVIRONMENT ########################

    dev|develop) . $CLI docker compose _up-dev "$@" ;;
    bpa|build) . $CLI docker compose _build "$@" ;;
    run) . $CLI docker compose _exec "$REPO_NAME" "$@" ;;
    exe|execute) . $CLI docker compose _exec "$@" ;;
    she|shell) . $CLI run /bin/bash "$@" ;;
    pus|push) . $CLI git _commit-push-pr "$@" ;;
    pul|pull) . $CLI git _pull "$@" ;;
    ins|insight) . $CLI git _insight "$@" ;;
    tes|test) . $KIT_SRC_DIR/cmds/test.sh "$@" ;;
    for|format)
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI on-bench $c "$@"; return 0; fi
        . $KIT_SRC_DIR/cmds/format.sh "$@"
    ;;

    ######################## SOURCE CONTROL ########################

    git)
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI on-bench $c "$@"; return 0; fi
        . $KIT_SRC_DIR/cmds/git/index.sh; c=$1; shift; case "$c" in
        sta|_status)
            . $CLI inform forbid-dev-on-main
            . $CLI inform _status-branch-status
            cmd_git_pr_check_status "$@"
        ;;
        cpp|_commit-push-pr) cmd_git_commit_push_pr "$@" ;;
        che|_checkout) cmd_git_checkout_branch "$@" ;;
        com|_commit) cmd_git_commit "$@" ;;
        pul|_pull) cmd_git_pull_merge "$@" ;;
        pus|_push) cmd_git_push "$@" ;;
        pre|_pull-request) cmd_git_pr_create "$@" ;;
        hea|_head) cmd_git_head "$@" ;;
        ins|_insight) cmd_git_daily_insight "$@" ;;
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
    esac;;

    ######################## INFRASTRUCTURE ########################

    doc|docker) c=$1; shift; case $c in
        com|compose) c=$1; shift; case $c in
            ude|_up|_up-dev) . $KIT_SRC_DIR/cmds/docker/up-development.sh "$@" ;;
            upr|_up-pro) . $KIT_SRC_DIR/cmds/docker/up-production.sh "$@" ;;
            exe|_exec) . $KIT_SRC_DIR/cmds/docker/execute.sh "$@" ;;
            bpa|_build) _docker compose build --parallel "$@" ;;
            hel|help|--help|-h) display_help "" "" \
                "$(color 30 'Docker Compose Commands')" "" \
                "    ude|_up|_up-dev  " "Start development environment" \
                "    upr|_up-pro      " "Start production environment" \
                "    exe|_exec        " "Execute command in compose service" \
                "    bpa|_build       " "Build all services in parallel" \
                "    <docker-compose-cmd>" "Pass through to docker compose"
            ;;
            *) _docker compose $c "$@" ;;
        esac ;;
        hel|help|--help|-h) display_help "" "" \
            "$(color 30 'Docker Commands')" "" \
            "    com|compose         " "Docker compose operations" \
            "    <docker-cmd>        " "Pass through to docker"
        ;;
        *) _docker $c "$@" ;;
    esac ;;

    wor|workspace)
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI on-bench $c "$@"; return 0; fi
        . $KIT_SRC_DIR/cmds/workspace/index.sh; c=$1; shift; case "$c" in
        ini|init) cmd_workspace_init ;;
        sel|select) cmd_workspace_select ;;
        sta|status) cmd_workspace_status ;;
        con|config) cmd_workspace_config "$@" ;;
        *) display_help  "" "" \
            "$(color 30 'Workspace Commands')" "" \
            "    ini|init      " "Initialize workspace configuration" \
            "    sel|select    " "Select modules for workspace" \
            "    sta|status    " "Show current workspace configuration" \
            "    con|config    " "Manage workspace configuration (get/set/delete/list)"
        ;;
    esac ;;

    ser|service) . $KIT_SRC_DIR/cmds/service.sh "$@" ;;

    pac|package) . $KIT_SRC_DIR/cmds/package.sh "$@" ;;

    ######################## CONFIGURATION ########################

    con|config)
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI on-bench $c "$@"; return 0; fi
        . $KIT_SRC_DIR/facades/config.sh; c=$1; shift; case "$c" in
        get) config_get "$@" ;;
        set) config_set "$@" ;;
        del|delete) config_delete "$@" ;;
        array_add) config_array_add "$@" ;;
        array_remove) config_array_remove "$@" ;;
        lis|list) config_keys "$@" ;;
        pri|print) config_print "$@" ;;
        *) display_help "" "" \
            "$(color 30 'Config Commands')" "" \
            "    get <key.path>                   " "Get value from configuration" \
            "    set <key.path> <value>           " "Set value in configuration" \
            "    del|delete <key.path>            " "Delete key from configuration" \
            "    array_add <key.path> <val>       " "Add item to array" \
            "    array_remove <key.path> <val>    " "Remove item from array" \
            "    lis|list                         " "List all configuration keys" \
            "    pri|print                        " "Print entire configuration"
        ;;
    esac ;;

    sec|secret)
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI on-bench $c "$@"; return 0; fi
        . $KIT_SRC_DIR/cmds/secret/index.sh; c=$1; shift; case $c in
        kse|key-set) cmd_secret_set_key "$@" ;;
        kre|key-reset) cmd_secret_reset_key "$@" ;;
        ksh|key-show) cmd_secret_show_key "$@" ;;
        add) cmd_secret_add_secret "$@" ;;
        exp|export) cmd_secret_export "$@" ;;
        sho|show) cmd_secret_show_secrets "$@" ;;
        cle|clear) cmd_secret_clear_secrets "$@" ;;
        rem|remove|rm|del|delete) cmd_secret_remove_secret "$@" ;;
        *) display_help "" "" \
            "$(color 30 'Secrets Commands')" "" \
            "    kse|key-set            " "Set encryption key manually" \
            "    kre|key-reset          " "Generate new key and re-encrypt all secrets" \
            "    ksh|key-show           " "Display current encryption key" \
            "    add                    " "Add a new secret interactively" \
            "    sho|show               " "Display all secrets in readable format" \
            "    exp|export             " "Export a secret value" \
            "    cle|clear              " "Remove all secrets (requires confirmation)" \
            "    rem|remove <name>      " "Remove a specific secret" \
            "" "" "$(color 34 'Info: ')" "Secrets are encrypted with AES-256-CBC using auto-generated keys" \
            "" "" "$(color 30 'Important: ')" "If secrets exist but no key is configured, you ust:" \
            "    1. Set the original key manually: secrets set-key" "" \
            "    2. Clear all secrets: secrets clear" ""
        ;;
    esac;;

    env|envs) message 34 "INFO" "Sourced repo envs" ;; # Source projects root cli to load environment variables. example: "source ./cli envs;"

    ######################## UTILITIES ########################

    inf|inform) c=$1; shift; case $c in
        csd|check-system-dependencies) . $KIT_SRC_DIR/informs/check-system-dependencies.sh "$@" ;;
        cic|check-internet-connection) . $KIT_SRC_DIR/informs/check-internet-connection.sh "$@" ;;
        fdm|forbid-dev-on-main) . $KIT_SRC_DIR/informs/forbid-dev-on-main.sh "$@" ;;
        sbs|_status-branch-status) . $KIT_SRC_DIR/informs/_status-branch-status.sh "$@" ;;
        cfu|check-for-updates) . $KIT_SRC_DIR/informs/check-for-updates.sh "$@" ;;
        *) display_help "" "" \
            "$(color 30 'Inform Commands')" "" \
            "    csd|check-system-dependencies   " "Check for missing system dependencies" \
            "    cic|check-internet-connection   " "Check if the internet connection is active" \
            "    fdm|forbid-dev-on-main          " "Warn if on 'main' branch" \
            "    sbs|_status-branch-status       " "Show local vs remote branch status" \
            "    cfu|check-for-updates           " "Check for CLI updates and notify"
        ;;
    esac ;;

    api) c=$1; shift; case "$c" in
        v1) c=$1; shift; case "$c" in
            install) . $CLI install "$@" ;;
            *) display_help "" "" \
                "$(color 30 'API v1 Commands')" "" \
                "    install     " "Install API v1 dependencies"
            ;;
        esac ;;
        *) display_help "" "" \
            "$(color 30 'API Commands')" "" \
            "    v1          " "API version 1 operations"
        ;;
    esac ;;

    kit)
        if [ "$TO_MOUNT_DIR" != "$KIT_DIR" ]; then
            export TO_MOUNT_DIR="$ROOT_DIR";
        fi
        . $KIT_DIR/cli "$@"
    ;;

    obe|on-bench) $CLI $KIT_NAME execute --no-message $KIT_NAME D "$@" ;;

    eve|event) . $KIT_SRC_DIR/facades/event.sh "$@" ;;

    int|internet) . $KIT_SRC_DIR/utils/internet/index.sh "$@" ;;

    ######################## INFORMATION ########################

    ver|version|--version) message 40 "v$VERSION" "DISEEC DevOps CLI — Automation Toolkit" ;;

    hel|help|--help|-h) display_help "" "" \
        "$(color 30 'Usage:    cli <command> [subcommand] [options] [arguments]\n')" "" \
        "$(color 30 'Project Management')" "" \
        "    ins|install              " "Install project dependencies and tools" \
        "    ude|update               " "Update CLI and sync project" \
        "    sta|status               " "Show comprehensive project status" \
        "" "" "$(color 30 'Development Environment')" "" \
        "    dev|develop              " "Start development environment" \
        "    bpa|build                " "Build project images" \
        "    run <command>            " "Execute command in container" \
        "    exe|execute <svc> <cmd>  " "Execute command in specific service" \
        "    she|shell                " "Open interactive shell" \
        "    tes|test [type]          " "Run test suites" \
        "    for|format               " "Format codebase" \
        "" "" "$(color 30 'Source Control')" "" \
        "    git                      " "Git workflow management" \
        "    pul|pull                 " "Pull and merge latest changes" \
        "    pus|push                 " "Auto-commit and create PR" \
        "" "" "$(color 30 'Infrastructure')" "" \
        "    doc|docker               " "Docker operations" \
        "    ser|service              " "Service management" \
        "    pac|package              " "Package management" \
        "    wor|workspace            " "Workspace configuration" \
        "" "" "$(color 30 'Configuration')" "" \
        "    con|config               " "Configuration management" \
        "    sec|secret              " "Encrypted secrets management" \
        "    env|envs                 " "Environment variables. Usage: source D envs" \
        "" "" "$(color 30 'Utilities')" "" \
        "    ins|insight              " "Generate development insights" \
        "    inf|inform               " "Information and validation" \
        "    obe|on-bench <command>   " "Safe command execution" \
        "    eve|event                " "Event handling" \
        "    api                      " "API operations" \
        "    kit <command>            " "SDK container operations" \
        "" "" "$(color 30 'Information')" "" \
        "    ver|version              " "Show version information" \
        "    hel|help                 " "Show this help message" \
        "$@"
    ;;
    *)
        if [ ! -z "$c" ]; then message 41 "error" "Unknown command: '$c'"; fi
        . $CLI help; exit 1;
    ;;
esac
