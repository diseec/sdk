#!/bin/bash

c=$1; shift; case $c in
    sta|status)     sdk_cmd_status "$@" ;;
    ins|install)    mark_ctx_only; source "$D_SDK_DIR/facades/install/cli.sh" "$@" ;;
    ude|update)     mark_ctx_only; cli_ctx install update "$@" ;;
    dev|develop)    mark_ctx_only; cli_ctx docker compose up-dev "$@" ;;
    bpa|build)      cli_ctx docker compose build "$@" ;;
    run)            cli_ctx docker compose execute "$D_REPO_NAME" "$@" ;;
    exe|execute)    cli_ctx docker compose execute "$@" ;;
    she|shell)      cli_ctx run /bin/bash "$@" ;;
    clo|clone)      cli_ctx git clone "$@" ;;
    pus|push)       mark_ctx_only; cli_ctx git commit-push-pr "$@" ;;
    pul|pull)       mark_ctx_only; cli_ctx git pull "$@" ;;
    dai|daily)      mark_ctx_only; cli_ctx git insight-day "$@" ;;
    pru|prune)      cli_ctx docker _ system prune "$@" ;;
    for|format)     mark_ctx_only; source_safely "$D_SDK_DIR/facades/format/cli.sh" prettier "$@" ;;
    sub|submodule)  mark_ctx_only; source_safely "$D_SDK_DIR/facades/submodule/cli.sh" "$@" ;;
    sec|secret)     mark_ctx_only; source_safely "$D_SDK_DIR/facades/secret/cli.sh" "$@" ;;
    inf|informs)    mark_ctx_only; source_safely "$D_SDK_DIR/facades/informs/cli.sh" "$@" ;;
    con|config)     mark_ctx_only; source_safely "$D_SDK_DIR/facades/config/cli.sh" "$@" ;;
    doc|docker)     source "$D_SDK_DIR/facades/docker/cli.sh" "$@" ;;
    git)            source_safely "$D_SDK_DIR/facades/git/cli.sh" "$@" ;;
    int|internet)   source_safely "$D_SDK_DIR/facades/internet/cli.sh" "$@" ;;
    # ain|ai)         source_safely "$D_SDK_DIR/facades/ai/cli.sh" "$@" ;;
    env|envs)       source "$D_SDK_DIR/bootstrap/environment/exports.sh" "$@" ;;
    sdk)            (env D_TARGET_CTX_DIR="$D_CTX_DIR" "$D_CLI_SDK" "$@") ;;
    api)            source "$D_SDK_DIR/api/cli.sh" "$@" ;;
    abo|about)      sdk_cmd_opt_about "$@" ;;

    # OPTION COMMANDS
    --version)      sdk_cmd_opt_version "$@" ;;
    -s|--safely)    sdk_cmd_opt_safely "$@" ;;
    -h|--help|hel|help) sdk_cmd_opt_help "$@" ;;

    # TEMPORARY ALIASES
    rst|run-sdk-tests|t) cli_core sdk tester run --verbose --fail-fast "$@" ;;
    
    # HOOKS
    hook:*) ;;
    # hook:before_update) stdout -i "Commands before updating completed..." ;;
    # hook:after_update)  stdout -i "Commands after updating completed..." ;;
    # hook:after_install) stdout -i "Commands before installing completed..." ;;
    # hook:after_install) stdout -i "Commands after installing completed..." ;;
    # hook:before_push)   stdout -i "Commands before pushing changes..." ;;
    # hook:after_push)    stdout -i "Commands after pushing changes..." ;;

    *) sdk_cmd_any "$@" ;;
esac
