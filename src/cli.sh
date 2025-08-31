#!/bin/bash

c=$1; shift; case "$c" in

    ######################## PROJECT MANAGEMENT ########################

    ins|install) cli_main setup project "$@" ;;
    ude|update) "$KIT_SRC_DIR/cmds/update.sh" "$@" ;;
    sta|status)         
        cli_main version
        cli_main workspace status
        cli_main inform check-system-dependencies
        cli_main inform check-internet-connection
        cli_main git status
        cli_main inform check-for-updates
    ;;

    ######################## DEVELOPMENT ENVIRONMENT ########################

    dev|develop) cli_main docker compose up-dev "$@" ;;
    bpa|build)   cli_main docker compose build "$@" ;;
    run)         cli_main docker compose exec "$REPO_NAME" "$@" ;;
    exe|execute) cli_main docker compose exec "$@" ;;
    she|shell)   cli_main run /bin/bash "$@" ;;
    pus|push)    cli_main git commit-push-pr "$@" ;;
    pul|pull)    cli_main git pull "$@" ;;
    dai|daily)   cli_main git insight-day "$@" ;;
    tes|test)    $KIT_SRC_DIR/cmds/test.sh "$@" ;;
    pru|prune)   cli_main docker system prune "$@" ;;
    for|format)  force_safe $c "$@" || source "$KIT_SRC_DIR/facades/format/cli.sh" prettier "$@" ;;

    ######################## FACADES ########################

    set|setup)     source "$KIT_SRC_DIR/facades/setup/cli.sh" "$@" ;;
    doc|docker)    source "$KIT_SRC_DIR/facades/docker/cli.sh" "$@" ;;
    int|internet)  force_safe $c "$@" || source "$KIT_SRC_DIR/facades/internet/cli.sh" "$@" ;;
    ain|ai)        force_safe $c "$@" || source "$KIT_SRC_DIR/facades/ai/cli.sh" "$@" ;;
    git)           force_safe $c "$@" || source "$KIT_SRC_DIR/facades/git/cli.sh" "$@" ;;
    sub|submodule) force_safe $c "$@" || source "$KIT_SRC_DIR/facades/submodule/cli.sh" "$@" ;;
    con|config)    force_safe $c "$@" || source "$KIT_SRC_DIR/facades/config/cli.sh" "$@" ;;
    sec|secret)    force_safe $c "$@" || source "$KIT_SRC_DIR/facades/secret/cli.sh" "$@" ;;
    wor|workspace) force_safe $c "$@" || source "$KIT_SRC_DIR/facades/workspace/cli.sh" "$@" ;;

    ######################## UTILITIES ########################

    env|envs) source "$KIT_SRC_DIR/envs/exports.sh" "$@" ;;

    inf|inform) source "$KIT_SRC_DIR/informs/index.sh" "$@" ;;

    kit) env KIT_TARGET_DIR="$ROOT_DIR" "$KIT_DIR/cli" "$@" ;;

    saf|safely) cli_main "$KIT_NAME" run --no-message "$TARGET_MOUNTED_DIR/cli" "$@" ;;

    api) c=$1; shift; case "$c" in
        v1) c=$1; shift; case "$c" in
            install) cli_main install "$@" ;;
            *) display_help "" "" \
                "$(color 37 'API v1 Commands')" "" \
                "    install     " "Install API v1 dependencies"
            ;;
        esac ;;
        *) display_help "" "" \
            "$(color 37 'API Commands')" "" \
            "    v1          " "API version 1 operations"
        ;;
    esac ;;

    ver|version)
        printf "\n"
        color 0 "\e[47m    DISEEC DevOps CLI \e[0m\e[1m\e[34m Automation Toolkit \e[0m\e[37mv$VERSION\n"
        printf "\n"
        color 30 "This software and associated documentation files\n(the \"Software\") are the  exclusive property  of\nDISEEC L.T.E. and are protected by copyright and\nother intellectual property laws.\nPermission is hereby granted, free of charge, to\nany person obtaining a copy of this Software, to\nse the Software within the organization only.\n"
        printf "\n"
        color 30 "\e[1mWebsite  \e[0m    https://diseec.com\n"
        color 30 "\e[1mGitHub   \e[0m    https://github.com/diseec\n"
        color 30 "\e[1mLinkedIn \e[0m    https://linkedin.com/company/diseec\n"
        printf "\n"
        color 30 "Copyright (c) 2018 DISEEC,  all rights  reserved\n"
        printf "\n"
    ;;

    hel|help|--help|-h) display_help "" "" \
        "$(color 37 'Usage:    bash cli <command> [subcommand] [options] [arguments]')" "" \
        "" "" "$(color 37 'Global Manager The D')" "" \
        "    D [--patch]              " "Project-scoped kit manager" \
        "    D                        " "Locate project root and invoke the project's ./cli" \
        "    D --patch                " "Force pull and reinstall kit into project" \
        "                             " "Note: 'D --patch' ensures a fresh kit binary is used when the local kit is missing," \
        "                             " "corrupted, or unable to bootstrap the CLI itself." \
        "" "" "$(color 37 'Project Management')" "" \
        "    ins|install              " "Install project dependencies and tools" \
        "    ude|update               " "Update cli_main and sync project" \
        "    sta|status               " "Show comprehensive project status" \
        "" "" "$(color 37 'Workflow & Environment')" "" \
        "    dev|develop              " "Start development environment" \
        "    bpa|build                " "Build project images" \
        "    run <command>            " "Execute command in container" \
        "    exe|execute <svc> <cmd>  " "Execute command in specific service" \
        "    she|shell                " "Open interactive shell" \
        "    tes|test [type]          " "Run test suites" \
        "    for|format               " "Format codebase" \
        "" "" "$(color 37 'Source Control')" "" \
        "    git                      " "Git workflow management" \
        "    pul|pull                 " "Pull and merge latest changes" \
        "    pus|push                 " "$(color 35 '✦') Auto-commit and create PR" \
        "" "" "$(color 37 'Infrastructure')" "" \
        "    doc|docker               " "Docker operations" \
        "    sub|submodule            " "Unified submodule management (packages & services)" \
        "    wor|workspace            " "Workspace configuration" \
        "" "" "$(color 37 'Configuration')" "" \
        "    con|config               " "Configuration management" \
        "    sec|secret               " "Encrypted secrets management" \
        "" "" "$(color 37 'Utilities')" "" \
        "    ai$(printf "\033[35m✦\033[0m\033[34m")                      " "Access to a comprehensive set of AI utils" \
        "    env|envs                 " "Manage environment variables. Example:" \
        "                             " "set -a; eval \"\$(D envs)\"; set +a" \
        "                             " "eval \$(cli_main envs) > /dev/null" \
        "    saf|safely <command>     " "Safe command execution" \
        "    api                      " "API operations" \
        "    kit <command>            " "SDK container operations" \
        "" "" "$(color 37 'Information')" "" \
        "    inf|inform               " "Information and validation" \
        "    dai|daily                " "$(color 35 '✦') Generate daily insights" \
        "    ver|version              " "Show version information" \
        "    hel|help                 " "Show this help message" \
        "$@"
    ;;
    *)
        if [ ! -z "$c" ]; then message 31 "E" "Unknown command: '$c'"; fi
        cli_main help; exit 1;
    ;;
esac
