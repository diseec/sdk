#!/bin/bash

c=$1; shift; case "$c" in

    ######################## PROJECT MANAGEMENT ########################

    ins|install) CLI setup project "$@" ;;
# XXXXXX
    ude|update) SRC_KIT "cmds/update.sh" "$@" ;;
    sta|status)         
        CLI version
        CLI workspace status
        CLI inform check-system-dependencies
        CLI inform check-internet-connection
        CLI git status
        CLI inform check-for-updates
    ;;

    ######################## DEVELOPMENT ENVIRONMENT ########################

    dev|develop) CLI docker compose up-dev "$@" ;;
    bpa|build)   CLI docker compose build "$@" ;;
    run)         CLI docker compose exec "$REPO_NAME" "$@" ;;
    exe|execute) CLI docker compose exec "$@" ;;
    she|shell)   CLI run /bin/bash "$@" ;;
    pus|push)    CLI git commit-push-pr "$@" ;;
    pul|pull)    CLI git pull "$@" ;;
    ins|insight) CLI git insight "$@" ;;
    tes|test)    SRC_KIT cmds/test.sh "$@" ;;
    pru|prune)   CLI docker system prune "$@" ;;
    for|format)  SAFELY $c "$@" && SRC_KIT cmds/format.sh "$@" ;;

    ######################## FACADES ########################

    set|setup)     SRC_KIT "facades/setup/index.sh" "$@" ;;
    sub|submodule) SRC_KIT "facades/submodule/index.sh" "$@" ;;
    doc|docker)    SRC_KIT "facades/docker/index.sh" "$@" ;;
    git)           SAFELY_SRC_KIT "facades/git/index.sh" $c "$@" ;;
    wor|workspace) SAFELY_SRC_KIT "facades/workspace/index.sh" $c "$@" ;;
    con|config)    SAFELY_SRC_KIT "facades/config/index.sh" $c "$@" ;;
    sec|secret)    SAFELY_SRC_KIT "facades/secret/index.sh" $c "$@" ;;
    ain|ai)        SAFELY_SRC_KIT "facades/ai/index.sh" $c "$@" ;;
    int|internet)  SRC_KIT "facades/internet/index.sh" "$@" ;;

    ######################## UTILITIES ########################

    env|envs) message 34 "INFO" "Sourced repo envs" ;; # Source projects root cli to load environment variables. example: "source ./cli envs;"

    inf|inform) SRC_KIT "informs/index.sh" "$@" ;;

    kit) export TO_MOUNT_DIR="$ROOT_DIR"; "$KIT_DIR/cli" "$@" ;;

    saf|safely) CLI "$KIT_NAME" run --no-message "/$PROJECT_MOUNT_DIR_NAME/cli" "$@" ;;

    api) c=$1; shift; case "$c" in
        v1) c=$1; shift; case "$c" in
            install) CLI install "$@" ;;
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

    ver|version|--version) message 40 "v$VERSION" "DISEEC DevOps CLI — Automation Toolkit" ;;

    hel|help|--help|-h) display_help "" "" \
        "$(color 30 'Usage:    bash cli <command> [subcommand] [options] [arguments]\n')" "" \
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
        "    sec|secret               " "Encrypted secrets management" \
        "    env|envs                 " "Environment variables. Usage: source D envs" \
        "" "" "$(color 30 'Utilities')" "" \
        "    ins|insight              " "Generate development insights" \
        "    inf|inform               " "Information and validation" \
        "    saf|safely <command>     " "Safe command execution" \
        "    api                      " "API operations" \
        "    kit <command>            " "SDK container operations" \
        "" "" "$(color 30 'Information')" "" \
        "    ver|version              " "Show version information" \
        "    hel|help                 " "Show this help message" \
        "$@"
    ;;
    *)
        if [ ! -z "$c" ]; then message 41 "error" "Unknown command: '$c'"; fi
        CLI help; exit 1;
    ;;
esac
