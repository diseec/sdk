#!/bin/bash

ARGS=(); for arg in "$@"; do
    if [[ "$arg" == "--debug" && -z "$SEEN_DEBUG" ]]; then SEEN_DEBUG=1
        export D_LOG_LEVEL="DEBUG" # See "message" function 
    # elif [[ "$arg" == "--example" && -z "$SEEN_EXAMPLE" ]]; then SEEN_EXAMPLE=1
    #     EXAMPLE="value"
else ARGS+=("$arg"); fi; done; set -- "${ARGS[@]}"

c=$1; shift; case $c in
    ins|install) cli_main setup project "$@" ;;
    ude|update) cli_main setup update "$@" ;;
    sta|status)         
        # cli_main about
        # bug "cli_main workspace status"
        cli_main workspace status
        # bug "src_inf_check_system_dependencies"
        # # cli_main informs src_inf_check_system_dependencies
        # bug "src_inf_check_internet_connection"
        cli_main informs src_inf_check_internet_connection
        # bug "cli_main git status"
        cli_main git status
        # bug "src_inf_check_for_updates"
        # cli_main informs src_inf_check_for_updates
    ;;
    dev|develop) cli_main docker compose up-dev "$@" ;;
    bpa|build)   cli_main docker compose build "$@" ;;
    run)         cli_main docker compose execute "$REPO_NAME" "$@" ;;
    exe|execute) cli_main docker compose execute "$@" ;;
    she|shell)   cli_main run /bin/bash "$@" ;;
    pus|push)    cli_main git commit-push-pr "$@" ;;
    pul|pull)    cli_main git pull "$@" ;;
    dai|daily)   cli_main git insight-day "$@" ;;
    tes|test)    $KIT_SRC_DIR/cmds/test.sh "$@" ;;
    pru|prune)   cli_main docker _ system prune "$@" ;;
    for|format)  force_safe $c "$@" || source "$KIT_SRC_DIR/facades/format/cli.sh" prettier "$@" ;;
    set|setup)     source "$KIT_SRC_DIR/facades/setup/cli.sh" "$@" ;;
    doc|docker)    source "$KIT_SRC_DIR/facades/docker/cli.sh" "$@" ;;
    int|internet)  force_safe $c "$@" || source "$KIT_SRC_DIR/facades/internet/cli.sh" "$@" ;;
    ain|ai)        force_safe $c "$@" || source "$KIT_SRC_DIR/facades/ai/cli.sh" "$@" ;;
    git)           force_safe $c "$@" || source "$KIT_SRC_DIR/facades/git/cli.sh" "$@" ;;
    sub|submodule) force_safe $c "$@" || source "$KIT_SRC_DIR/facades/submodule/cli.sh" "$@" ;;
    con|config)    force_safe $c "$@" || source "$KIT_SRC_DIR/facades/config/cli.sh" "$@" ;;
    sec|secret)    force_safe $c "$@" || source "$KIT_SRC_DIR/facades/secret/cli.sh" "$@" ;;
    wor|workspace) force_safe $c "$@" || source "$KIT_SRC_DIR/facades/workspace/cli.sh" "$@" ;;
    inf|informs)   force_safe $c "$@" || source "$KIT_SRC_DIR/informs/cli.sh" "$@" ;;
    env|envs) source "$KIT_SRC_DIR/envs/exports.sh" "$@" ;;
    kit) env KIT_TARGET_DIR="$ROOT_DIR" "$KIT_DIR/cli" "$@" ;;
    saf|safely)
        # logit -d "CLI:$CLI_CORE:SAFELY:ARGS: $@";
        cli_main "$KIT_NAME" stop > /dev/null 2>&1 || true ;
        cli_main "$KIT_NAME" run --quiet "$TARGET_MOUNTED_DIR/cli" "$@"
        # cli_main "$KIT_NAME" run "$TARGET_MOUNTED_DIR/cli" "$@"
        # if [ $? -ne 0 ]; then logit -e "Failed to run command in $KIT_NAME container"; fi
    ;;
    api) c=$1; shift; case $c in
        v1) c=$1; shift; case $c in
            install) cli_main install "$@" ;;
            *) display_help "" "" \
                "$(ansi 97 'API v1 Commands')" "" \
                "    install     " "Install API v1 dependencies"
            ;;
        esac ;;
        *) display_help "" "" \
            "$(ansi 97 'API Commands')" "" \
            "    v1          " "API version 1 operations"
        ;;
    esac ;;
    abo|about) about ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[D]/[bash cli] [command] [subcommand] [options] [arguments]" \
        "                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$ORG_NAME/$KIT_NAME")")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Global Manager The "D"')")" "" \
        "    D [option] [arguments]   " "Locate project root and invoke the project's ./cli" \
        "        about                " "About $KIT_NAME, authors, $ORG_NAME, policies and licensing" \
        "    $(ansi 90 'Options:')" "" \
        "        --patch              " "Force pull and reinstall kit into project" \
        "                             " "$(ansi "2;90" "Ensures a fresh kit binary is used,")" \
        "                             " "$(ansi "2;90" "when the local kit is missing, corrupted,")" \
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
        "    run <command>            " "Execute command in container" \
        "    exe|execute <svc> <cmd>  " "Execute command in specific service" \
        "    she|shell                " "Open interactive shell" \
        "    tes|test [type]          " "Run test suites" \
        "    for|format               " "Format codebase" \
        "" "" "$(ansi "1;90" "$(capitalize 'Source Control')")" "" \
        "    git                      " "Git workflow management" \
        "    pul|pull                 " "Pull and merge latest changes" \
        "    pus|push                 " "$(ansi 96 '✦') $(ansi 90 'Auto-commit and create PR')" \
        "" "" "$(ansi "1;90" "$(capitalize 'Infrastructure')")" "" \
        "    doc|docker               " "Docker operations" \
        "    sub|submodule            " "Unified submodule management (packages & services)" \
        "    wor|workspace            " "Workspace configuration" \
        "" "" "$(ansi "1;90" "$(capitalize 'Configuration')")" "" \
        "    con|config               " "Configuration management" \
        "    sec|secret               " "Encrypted secrets management" \
        "" "" "$(ansi "1;90" "$(capitalize 'Utilities')")" "" \
        "    ai$(printf "\033[96m✦\033[0m\033[34m")                      " "Access to a comprehensive set of AI utils" \
        "    env|envs                 " "Manage environment variables. Examples:" \
        "                             " "$(ansi "2;90" 'set -a; eval "$(D envs)"; set +a')" \
        "                             " "$(ansi "2;90" 'eval "$(cli_main envs)" > /dev/null')" \
        "    saf|safely <command>     " "Safe command execution" \
        "    api                      " "API operations" \
        "    kit <command>            " "SDK container operations" \
        "$@"
    ;;
    -v|--version) echo "$VERSION" ;;
    *)
        logit -e "Unknown command: '$c'"
        cli_main help; exit 1;
    ;;
esac
