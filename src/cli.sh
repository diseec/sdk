#!/bin/bash

c=$1; shift; case "$c" in

    ######################## PROJECT MANAGEMENT ########################

    sys|system) . "$KIT_SRC_DIR/cmds/install/system.sh" "$@" ;;
    ins|install) . "$KIT_SRC_DIR/cmds/install/project.sh" "$@" ;;
    ude|update) . "$KIT_SRC_DIR/cmds/update.sh" "$@" ;;
    sta|status)         
        . "$CLI" version
        . "$CLI" workspace status
        . "$CLI" inform check-system-dependencies
        . "$CLI" inform check-internet-connection
        . "$CLI" git _status
        . "$CLI" inform check-for-updates
    ;;

    ######################## DEVELOPMENT ENVIRONMENT ########################

    dev|develop) . "$CLI" docker compose _up-dev "$@" ;;
    bpa|build) . "$CLI" docker compose _build "$@" ;;
    run) . "$CLI" docker compose _exec "$REPO_NAME" "$@" ;;
    exe|execute) . "$CLI" docker compose _exec "$@" ;;
    she|shell) . "$CLI" run /bin/bash "$@" ;;
    pus|push) . "$CLI" git _commit-push-pr "$@" ;;
    pul|pull) . "$CLI" git _pull "$@" ;;
    ins|insight) . "$CLI" git _insight "$@" ;;
    tes|test) . "$KIT_SRC_DIR/cmds/test.sh" "$@" ;;
    for|format) on_bench "$KIT_SRC_DIR/cmds/format.sh" "$@" ;;

    ######################## SOURCE CONTROL ########################

    git) on_bench "$KIT_SRC_DIR/facades/git/index.sh" "$@" ;;
    doc|docker) . "$KIT_SRC_DIR/facades/docker/index.sh" "$@" ;;

    ######################## INFRASTRUCTURE ########################

    wor|workspace) on_bench "$KIT_SRC_DIR/facades/workspace/index.sh" "$@" ;;
    sub|submodule) . "$KIT_SRC_DIR/facades/submodule.sh" "$@" ;;

    ######################## CONFIGURATION ########################

    con|config) on_bench "$KIT_SRC_DIR/facades/config.sh" "$@" ;;

    sec|secret) on_bench "$KIT_SRC_DIR/facades/secret/index.sh" "$@" ;;

    env|envs) message 34 "INFO" "Sourced repo envs" ;; # Source projects root cli to load environment variables. example: "source ./cli envs;"

    ######################## UTILITIES ########################

    inf|inform) . "$KIT_SRC_DIR/informs/index.sh" "$@" ;;

    api) c=$1; shift; case "$c" in
        v1) c=$1; shift; case "$c" in
            install) . "$CLI" install "$@" ;;
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

    kit) export TO_MOUNT_DIR="$ROOT_DIR"; "$KIT_DIR/cli" "$@" ;;

    obe|on-bench) . "$CLI" "$KIT_NAME" execute --no-message "$KIT_NAME" '/vise/cli' "$@" ;;

    eve|event) . "$KIT_SRC_DIR/facades/event.sh" "$@" ;;

    int|internet) . "$KIT_SRC_DIR/utils/internet/index.sh" "$@" ;;

    ain|ai) on_bench "$KIT_SRC_DIR/utils/ai/index.sh" "$@" ;;

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
        "    sub|submodule            " "Unified submodule management (packages & services)" \
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
        . "$CLI" help; exit 1;
    ;;
esac
