#!/bin/sh

c=$1; shift; case $c in

    ######################## PROJECT MANAGEMENT ########################

    sys|system) . $KIT_SRC_DIR/cmds/install/system.sh "$@" ;;
    ins|install) . $KIT_SRC_DIR/cmds/install/project.sh "$@" ;;
    upd|update) . $KIT_SRC_DIR/cmds/update.sh; cmd_update "$@" ;;
    sta|status)         
        . $CLI version
        . $CLI workspace status
        . $CLI inform check-system-dependencies
        . $CLI inform check-internet-connection
        . $CLI git summary
        . $CLI inform check-for-updates
    ;;

    ######################## DEVELOPMENT ENVIRONMENT ########################

    dev|develop) . $CLI docker compose up-development "$@" ;;
    bui|build) . $CLI docker compose build-parallel "$@" ;;
    run) . $CLI docker compose execute "$REPO_NAME" "$@" ;;
    exe|execute) . $CLI docker compose execute "$@" ;;
    she|shell) . $CLI run /bin/bash "$@" ;;
    tes|test) . $KIT_SRC_DIR/cmds/test.sh "$@" ;;
    for|format) . $KIT_SRC_DIR/cmds/format.sh "**/*.{js,jsx,ts,tsx,json,css,scss,md}" ;;

    ######################## SOURCE CONTROL ########################

    git) . $KIT_SRC_DIR/cmds/git.sh; c=$1; shift; case "$c" in
        sum|summary)
            . $CLI inform forbid-dev-on-main
            . $CLI inform summary-branch-status
            cmd_git_check_pr_status "$@"
        ;;
        prc|pr-create) cmd_git_create_or_update_pr "$@" ;;
        mer|merge-pull) cmd_git_pull "$@" ;;
        rel|release) cmd_git_release "$@" ;;
        hel|help|--help|-h)
            display_help \
                "" "" \
                "$(color 30 'Git Commands')" "" \
                "    sum|summary       " "Check current branch PR status and unresolved comments" \
                "    prc|pr-create     " "Auto-commit with AI message and create/update PR" \
                "    mer|merge-pull    " "Pull latest changes and merge with main" \
                "    rel|release       " "Create release tag (development command)"
        ;;
        *) _git $c "$@" ;;
    esac;;
    pus|push) . $CLI git pr-create "$@" ;;
    pul|pull) . $CLI git merge-pull "$@" ;;

    ######################## INFRASTRUCTURE ########################

    doc|docker) c=$1; shift; case $c in
        com|compose) c=$1; shift; case $c in
            upd|up-development) . $KIT_SRC_DIR/cmds/docker/up-development.sh "$@" ;;
            upp|up-production) . $KIT_SRC_DIR/cmds/docker/up-production.sh "$@" ;;
            exe|execute) . $KIT_SRC_DIR/cmds/docker/execute.sh "$@" ;;
            bui|build-parallel) _docker compose build --parallel "$@" ;;
            hel|help|--help|-h)
                display_help \
                    "" "" \
                    "$(color 30 'Docker Compose Commands')" "" \
                    "    upd|up-development  " "Start development environment" \
                    "    upp|up-production   " "Start production environment" \
                    "    exe|execute         " "Execute command in compose service" \
                    "    bui|build-parallel  " "Build all services in parallel" \
                    "    <docker-compose-cmd>" "Pass through to docker compose"
            ;;
            *) _docker compose $c "$@" ;;
        esac ;;
        hel|help|--help|-h)
            display_help \
                "" "" \
                "$(color 30 'Docker Commands')" "" \
                "    com|compose         " "Docker compose operations" \
                "    <docker-cmd>        " "Pass through to docker"
        ;;
        *) _docker $c "$@" ;;
    esac ;;
    ser|service) . $KIT_SRC_DIR/cmds/service.sh "$@" ;;
    pac|package) . $KIT_SRC_DIR/cmds/package.sh "$@" ;;
    wor|workspace)
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI safe $c "$@"; return 0; fi
        . $KIT_SRC_DIR/cmds/workspace/index.sh; c=$1; shift; case "$c" in
        ini|init) cmd_workspace_init ;;
        sel|select) cmd_workspace_select ;;
        sta|status) cmd_workspace_status ;;
        con|config) cmd_workspace_config "$@" ;;
        *)
            display_help \
                "" "" \
                "$(color 30 'Workspace Commands')" "" \
                "    ini|init      " "Initialize workspace configuration" \
                "    sel|select    " "Select modules for workspace" \
                "    sta|status    " "Show current workspace configuration" \
                "    con|config    " "Manage workspace configuration (get/set/delete/list)"
        ;;
    esac ;;

    ######################## CONFIGURATION ########################

    con|config)
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI safe $c "$@"; return 0; fi
        . $KIT_SRC_DIR/facades/config.sh; c=$1; shift; case "$c" in
        get) config_get "$@" ;;
        set) config_set "$@" ;;
        del|delete) config_delete "$@" ;;
        array_add) config_array_add "$@" ;;
        array_remove) config_array_remove "$@" ;;
        lis|list) config_keys "$@" ;;
        pri|print) config_print "$@" ;;
        *)
            display_help \
                "" "" \
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
        if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then $CLI safe $c "$@"; return 0; fi
        . $KIT_SRC_DIR/cmds/secret.sh; c=$1; shift; case $c in
        kse|key-set) cmd_secret_set_key "$@" ;;
        kre|key-reset) cmd_secret_reset_key "$@" ;;
        ksh|key-show) cmd_secret_show_key "$@" ;;
        add) cmd_secret_add_secret "$@" ;;
        exp|export) cmd_secret_export "$@" ;;
        sho|show) cmd_secret_show_secrets "$@" ;;
        cle|clear) cmd_secret_clear_secrets "$@" ;;
        rem|remove|rm) cmd_secret_remove_secret "$@" ;;
        # deb|debug) cmd_secret_debug "$@" ;;
        *)
            display_help \
                "" "" \
                "$(color 30 'Secrets Commands')" "" \
                "    kse|key-set            " "Set encryption key manually" \
                "    kre|key-reset          " "Generate new key and re-encrypt all secrets" \
                "    ksh|key-show           " "Display current encryption key" \
                "    add                    " "Add a new secret interactively" \
                "    sho|show               " "Display all secrets in readable format" \
                "    exp|export             " "Export a secret value" \
                "    cle|clear              " "Remove all secrets (requires confirmation)" \
                "    rem|remove <name>      " "Remove a specific secret" \
                "" "" \
                "$(color 34 'Info: ')" "Secrets are encrypted with AES-256-CBC using auto-generated keys" \
                "" "" \
                "$(color 30 'Important: ')" "If secrets exist but no key is configured, you ust:" \
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
        sbs|summary-branch-status) . $KIT_SRC_DIR/informs/summary-branch-status.sh "$@" ;;
        cfu|check-for-updates) . $KIT_SRC_DIR/informs/check-for-updates.sh "$@" ;;
        *)
            display_help \
                "" "" \
                "$(color 30 'Inform Commands')" "" \
                "    csd|check-system-dependencies   " "Check for missing system dependencies" \
                "    cic|check-internet-connection   " "Check if the internet connection is active" \
                "    fdm|forbid-dev-on-main          " "Warn if on 'main' branch" \
                "    sbs|summary-branch-status       " "Show local vs remote branch status" \
                "    cfu|check-for-updates           " "Check for CLI updates and notify"
        ;;
    esac ;;
    saf|safe) $CLI $KIT_NAME execute --no-message $KIT_NAME D "$@" ;;
    eve|event) . $KIT_SRC_DIR/facades/event.sh "$@" ;;
    int|internet) . $KIT_SRC_DIR/utils/internet/index.sh "$@" ;;
    api) c=$1; shift; case "$c" in
        v1) c=$1; shift; case "$c" in
            install) . $CLI install "$@" ;;
            *)
                display_help \
                    "" "" \
                    "$(color 30 'API v1 Commands')" "" \
                    "    install     " "Install API v1 dependencies"
            ;;
        esac ;;
        *)
            display_help \
                "" "" \
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

    ######################## INFORMATION ########################

    ver|version|--version) message 40 "v$VERSION" "DISEEC DevOps CLI — Automation Toolkit" ;;
    hel|help|--help|-h)
        display_help \
            "" "" \
            "$(color 30 'Usage:    cli <command> [subcommand] [options] [arguments]\n')" "" \
            "$(color 30 'Project Management')" "" \
            "    ins|install              " "Install project dependencies and tools" \
            "    upd|update               " "Update CLI and sync project" \
            "    sta|status               " "Show comprehensive project status" \
            "" "" \
            "$(color 30 'Development Environment')" "" \
            "    dev|develop              " "Start development environment" \
            "    bui|build                " "Build project images" \
            "    run <command>            " "Execute command in container" \
            "    exe|execute <svc> <cmd>  " "Execute command in specific service" \
            "    she|shell                " "Open interactive shell" \
            "    tes|test [type]          " "Run test suites" \
            "    for|format               " "Format codebase" \
            "" "" \
            "$(color 30 'Source Control')" "" \
            "    git                      " "Git workflow management" \
            "    pul|pull                 " "Pull and merge latest changes" \
            "    pus|push                 " "Auto-commit and create PR" \
            "" "" \
            "$(color 30 'Infrastructure')" "" \
            "    doc|docker               " "Docker operations" \
            "    ser|service              " "Service management" \
            "    pac|package              " "Package management" \
            "    wor|workspace            " "Workspace configuration" \
            "" "" \
            "$(color 30 'Configuration')" "" \
            "    con|config               " "Configuration management" \
            "    sec|secret              " "Encrypted secrets management" \
            "    env|envs                 " "Environment variables. Usage: source D envs" \
            "" "" \
            "$(color 30 'Utilities')" "" \
            "    inf|inform               " "Information and validation" \
            "    saf|safe <command>       " "Safe command execution" \
            "    eve|event                " "Event handling" \
            "    api                      " "API operations" \
            "    kit <command>            " "SDK container operations" \
            "" "" \
            "$(color 30 'Information')" "" \
            "    ver|version              " "Show version information" \
            "    hel|help                 " "Show this help message" \
            "$@"
    ;;
    *)
        if [ ! -z "$c" ]; then message 41 "error" "Unknown command: '$c'"; fi
        . $CLI help; exit 1;
    ;;
esac
