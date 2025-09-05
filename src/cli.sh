#!/bin/bash

c=$1; shift; case $c in
    sta|status)         
        # # cli_main about
        # X "cli_main config summary"
        cli_main config summary
        # X "src_inf_check_system_dependencies"
        cli_main informs src_inf_check_system_dependencies
        # X "src_inf_check_internet_connection"
        cli_main informs src_inf_check_internet_connection
        # X "cli_main git status"
        cli_main git status
        # X "src_inf_check_for_updates"
        cli_main informs src_inf_check_for_updates
    ;;
    ins|install)    source "$SDK_SRC_DIR/facades/install/cli.sh" "$@" ;;
    ude|update)     cli_main install update "$@" ;;
    dev|develop)    cli_main docker compose up-dev "$@" ;;
    bpa|build)      cli_main docker compose build "$@" ;;
    run)            cli_main docker compose execute "$REPO_NAME" "$@" ;;
    exe|execute)    cli_main docker compose execute "$@" ;;
    she|shell)      cli_main run /bin/bash "$@" ;;
    pus|push)       cli_main git commit-push-pr "$@" ;;
    pul|pull)       cli_main git pull "$@" ;;
    dai|daily)      cli_main git insight-day "$@" ;;
    tes|test)       $SDK_SRC_DIR/cmds/test.sh "$@" ;;
    pru|prune)      cli_main docker _ system prune "$@" ;;
    for|format)     source_safely "$SDK_SRC_DIR/facades/format/cli.sh" prettier "$@" ;;
    doc|docker)     source "$SDK_SRC_DIR/facades/docker/cli.sh" "$@" ;;
    int|internet)   source_safely "$SDK_SRC_DIR/facades/internet/cli.sh" "$@" ;;
    ain|ai)         source_safely "$SDK_SRC_DIR/facades/ai/cli.sh" "$@" ;;
    git)            source_safely "$SDK_SRC_DIR/facades/git/cli.sh" "$@" ;;
    sub|submodule)  source "$SDK_SRC_DIR/facades/submodule/cli.sh" "$@" ;;
    con|config)     source_safely "$SDK_SRC_DIR/facades/config/cli.sh" "$@" ;;
    sec|secret)     source_safely "$SDK_SRC_DIR/facades/secret/cli.sh" "$@" ;;
    set|settings)   source_safely "$SDK_SRC_DIR/facades/settings/cli.sh" "$@" ;;
    inf|informs)    source "$SDK_SRC_DIR/informs/cli.sh" "$@" ;;
    env|envs)       source "$SDK_SRC_DIR/core/envs/exports.sh" "$@" ;;
    sdk)            env WORK_DIR_HOST="$WORK_DIR" "$SDK_DIR/cli" "$@" ;;
    api)            source "$SDK_SRC_DIR/api/cli.sh" "$@" ;;
    abo|about)      about ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[D]/[bash cli] [command] [subcommand] [options] [arguments]" \
        "                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$ORG_NAME/$SDK_NAME")")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Global Manager The "D"')")" "" \
        "    D [option] [arguments]   " "Locate project root and invoke the project's ./cli" \
        "        about                " "About $SDK_NAME, authors, $ORG_NAME, policies and licensing" \
        "    $(ansi 90 'Options:')" "" \
        "        --patch              " "Force pull and reinstall sdk into project" \
        "                             " "$(ansi "2;90" "Ensures a fresh sdk binary is used,")" \
        "                             " "$(ansi "2;90" "when the local sdk is missing, corrupted,")" \
        "                             " "$(ansi "2;90" "or unable to bootstrap the CLI itself.")" \
        "        --log-level          " "Set the log level for the CLI, valid values: DEBUG, INFO, WARNING, ERROR" \
        "        -v|--version         " "Show version information" \
        "        -h|--help            " "Brief usage and docs information" \
        "" "" "$(ansi "1;90" "$(capitalize 'Project Management')")" "" \
        "    ins|install              " "Install project dependencies and tools" \
        "    ude|update               " "Update cli_main and sync project" \
        "    sta|status               " "Show comprehensive project status" \
        "" "" "$(ansi "1;90" "$(capitalize 'Workflow & Environment')")" "" \
        "    dai|daily                " "$(ansi 36 '✦') $(ansi 90 'Generate daily insights')" \
        "    dev|develop              " "Start development environment" \
        "    bpa|build                " "Build project images" \
        "    run                      " "Execute command in container" \
        "    exe|execute              " "Execute command in specific service" \
        "    she|shell                " "Open interactive shell" \
        "    tes|test                 " "Run test suites" \
        "    for|format               " "Format codebase" \
        "" "" "$(ansi "1;90" "$(capitalize 'Source Control')")" "" \
        "    git                      " "Git workflow management" \
        "    pul|pull                 " "Pull and merge latest changes" \
        "    pus|push                 " "$(ansi 96 '✦') $(ansi 90 'Auto-commit and create PR')" \
        "" "" "$(ansi "1;90" "$(capitalize 'Infrastructure')")" "" \
        "    doc|docker               " "Docker operations" \
        "" "" "$(ansi "1;90" "$(capitalize 'Configuration')")" "" \
        "    wor|workspace            " "Workspace configuration" \
        "    con|config               " "Configuration management" \
        "    set|settings             " "Settings operations" \
        "    sub|submodule            " "Unified submodule management (packages & services)" \
        "    sec|secret               " "Encrypted secrets management" \
        "" "" "$(ansi "1;90" "$(capitalize 'Utilities')")" "" \
        "    ai$(printf "\033[96m✦\033[0m\033[34m")                      " "Access to a comprehensive set of AI utils" \
        "    env|envs                 " "Manage environment variables. Examples:" \
        "                             " "$(ansi "2;90" 'set -a; eval "$(D envs)"; set +a')" \
        "                             " "$(ansi "2;90" 'eval "$(cli_main envs)" > /dev/null')" \
        "    saf|safely               " "Safe command execution" \
        "    api                      " "API operations" \
        "    sdk                      " "SDK container operations" \
        "$@"
    ;;
    saf|safely)
        # logit -d "CLI:$CLI_CORE:SAFELY:ARGS: $@";
        cli_main "$SDK_NAME" stop > /dev/null 2>&1 || true ;
        # cli_main "$SDK_NAME" run --quiet "$WORK_DIR_CONTAINER/cli" "$@"
        cli_main "$SDK_NAME" run "$WORK_DIR_CONTAINER/cli" "$@"
        # if [ $? -ne 0 ]; then logit -e "Failed to run command in $SDK_NAME container"; fi
    ;;
    -v|--version)
        echo "$SDK_NAME: v$VERSION source: $SDK_DIR"
        d_version="$(_npm list -g @diseec/sdk --depth=0 --json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[", ]//g')"
        echo "D-cli: v$d_version"
        echo "Image ID: $(_docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "$SDK_IMAGE")"
    ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_main help; exit 1;
    ;;
esac
