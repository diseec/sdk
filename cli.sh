#!/bin/bash

c=$1; shift; case $c in
    sta|status)
        mark_ctx_only
        # # cli_stub about
        # X "cli_stub config summary"
        cli_stub config summary
        # X "sdk_inf_check_system_dependencies"
        cli_stub informs sdk_inf_check_system_dependencies
        # X "sdk_inf_check_internet_connection"
        cli_stub informs sdk_inf_check_internet_connection
        # X "cli_stub git status"
        cli_stub git status
        # X "sdk_inf_check_for_updates"
        cli_stub informs sdk_inf_check_for_updates
    ;;
    ins|install)    mark_ctx_only; source "$D_SDK_DIR/facades/install/cli.sh" "$@" ;;
    ude|update)     mark_ctx_only; cli_stub install update "$@" ;;
    dev|develop)    mark_ctx_only; cli_stub docker compose up-dev "$@" ;;
    bpa|build)      mark_ctx_only; cli_stub docker compose build "$@" ;;
    run)            mark_ctx_only; cli_stub docker compose execute "$D_REPO_NAME" "$@" ;;
    exe|execute)    mark_ctx_only; cli_stub docker compose execute "$@" ;;
    she|shell)      mark_ctx_only; cli_stub run /bin/bash "$@" ;;
    pus|push)       mark_ctx_only; cli_stub git commit-push-pr "$@" ;;
    pul|pull)       mark_ctx_only; cli_stub git pull "$@" ;;
    dai|daily)      mark_ctx_only; cli_stub git insight-day "$@" ;;
    tes|test)       mark_ctx_only; $D_SDK_DIR/cmds/test.sh "$@" ;; # TODO
    pru|prune)      mark_ctx_only; cli_stub docker _ system prune "$@" ;;
    for|format)     mark_ctx_only; source_safely "$D_SDK_DIR/facades/format/cli.sh" prettier "$@" ;;
    doc|docker)     mark_ctx_only; source "$D_SDK_DIR/facades/docker/cli.sh" "$@" ;;
    int|internet)   mark_ctx_only; source_safely "$D_SDK_DIR/facades/internet/cli.sh" "$@" ;;
    ain|ai)         mark_ctx_only; source_safely "$D_SDK_DIR/facades/ai/cli.sh" "$@" ;;
    git)            mark_ctx_only; source_safely "$D_SDK_DIR/facades/git/cli.sh" "$@" ;;
    sub|submodule)  mark_ctx_only; source "$D_SDK_DIR/facades/submodule/cli.sh" "$@" ;;
    con|config)     mark_ctx_only; source_safely "$D_SDK_DIR/facades/config/cli.sh" "$@" ;;
    sec|secret)     mark_ctx_only; source_safely "$D_SDK_DIR/facades/secret/cli.sh" "$@" ;;
    set|settings)   mark_ctx_only; source_safely "$D_SDK_DIR/facades/settings/cli.sh" "$@" ;;
    inf|informs)    mark_ctx_only; source "$D_SDK_DIR/informs/cli.sh" "$@" ;;
    env|envs)       mark_ctx_only; source "$D_SDK_DIR/bootstrap/environment/exports.sh" "$@" ;;
    sdk)            mark_ctx_only; env D_CTX_DIR_HOST="$D_CTX_DIR" "$D_SDK_DIR/$D_SDK_NAME" "$@" ;;
    api)            mark_ctx_only; source "$D_SDK_DIR/api/cli.sh" "$@" ;;
    abo|about)      mark_ctx_only; about ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[$D_CLI_GLOBAL_NAME]/[bash $D_CLI_LOCAL_NAME] [command] [subcommand] [options] [arguments]" \
        "                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$D_ORG_NAME/$D_SDK_NAME")")" \
        "" "" "$(ansi "1;90" "$(capitalize 'Global Manager The "$D_CLI_GLOBAL_NAME"')")" "" \
        "    $D_CLI_GLOBAL_NAME [option] [arguments]   " "Locate project root and invoke the project's ./$D_CLI_LOCAL_NAME" \
        "        about                " "About $D_SDK_NAME, authors, $D_ORG_NAME, policies and licensing" \
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
        "    ude|update               " "Update cli_stub and sync project" \
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
        "                             " "$(ansi "2;90" 'set -a; eval "$($D_CLI_GLOBAL_NAME envs)"; set +a')" \
        "                             " "$(ansi "2;90" 'eval "$(cli_stub envs)" > /dev/null')" \
        "    saf|safely               " "Safe command execution" \
        "    api                      " "API operations" \
        "    sdk                      " "SDK container operations" \
        "$@"
    ;;
    saf|safely)
        mark_ctx_only
        # logit -d "CLI:$D_CLI_CORE:SAFELY:ARGS: $@";
        cli_stub "$D_SDK_NAME" stop > /dev/null 2>&1 || true ;
        cli_stub "$D_SDK_NAME" run --quiet "$D_CTX_DIR_CONTAINER/$D_CLI_LOCAL_NAME" "$@"
        # cli_stub "$D_SDK_NAME" run "$D_CTX_DIR_CONTAINER/$D_CLI_LOCAL_NAME" "$@"
        # if [ $? -ne 0 ]; then logit -e "Failed to run command in $D_SDK_NAME container"; fi
    ;;
    -v|--version)
        set +e
        build_id="$(_docker images --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep "$D_SDK_IMAGE" | head -1 | awk '{print $1}')"
        d_version="$(_npm list -g $D_SDK_NPM_PKG --depth=0 --json 2>/dev/null | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[", ]//g')"
        release_date="$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$D_SDK_DIR/package.json")"
        echo "$(ansi 90 "$(capitalize "$D_CLI_GLOBAL_NAME-$D_SDK_NAME") Version") $(ansi 97 "$D_VERSION") $(ansi 90 "$release_date")"
        echo "$(ansi 90 "$D_CLI_GLOBAL_NAME-CLI Version") $(ansi 97 "$d_version") $(ansi 90 "Build") $(ansi 97 "$build_id")"
        echo "$(ansi "2;90" "$D_CLI_GLOBAL_NAME-SRC") $(ansi "2;90" "$D_SDK_DIR")"
        echo "$(ansi "2;90" "$D_CLI_GLOBAL_NAME-CTX") $(ansi "2;90" "$D_CTX_DIR")"
    ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_stub help; exit 1;
    ;;
esac
