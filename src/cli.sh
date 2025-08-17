#!/bin/sh

. $KIT_DIR/index.sh;

command=$1; shift; case $command in

    # Essential Functional Ops
    ins|install) cmd_install "$@" ;;
    upd|update) . $KIT_SRC_DIR/cmds/update.sh; cmd_update "$@" ;;
    exe|exec) cmd_exec "$@" ;;
    sta|status) 
        $CLI workspace status
        $CLI git status
        informer check-for-updates
    ;;

    # Optional Functional Ops
    dev) cmd_dev "$@" ;;
    pro) cmd_pro "$@" ;;
    pul|pull) $CLI git pull "$@" ;;
    pus|push) $CLI git push "$@" ;;
    rel|release) $CLI git release "$@" ;;
    bui|build) cmd_build "$@" ;;
    run) $CLI exec "$REPO_NAME" "$@" ;;
    she|shell) cmd_shell "$@" ;;
    for|format) cmd_format "**/*.{js,jsx,ts,tsx,json,css,scss,md}" ;;
    tes|test) cmd_test "$@" ;;

    # Managers
    kit|ops|devops) $KIT_DIR/cli "$@" ;;
    
    wor|workspace) . $KIT_SRC_DIR/workspace.sh; subcommand=$1; shift; case "$subcommand" in
        ini|init) cmd_workspace_init ;;
        sel|select) cmd_workspace_select ;;
        sta|status) cmd_workspace_status ;;
        *)
            message 33 "WORKSPACE" "Available workspace commands:"
            echo "  ini|init      - Initialize workspace configuration"
            echo "  sel|select    - Select modules for workspace"
            echo "  sta|status    - Show current workspace configuration"
            echo "           (Can pass custom commands: workspace sync 'command1' 'command2')"
        ;;
    esac ;;

    git) . $KIT_SRC_DIR/git.sh; subcommand=$1; shift; case "$subcommand" in
        status)
            informer forbid-dev-on-main
            informer summary-branch-status
            check_pr_status "$@"
        ;;
        pus|push) create_or_update_pr "$@" ;;
        pul|pull) pull "$@" ;;
        rel|release) release "$@" ;;
        *)
            message 33 "git" "Available git commands:"
            echo "  status   - Check status of current branch's PR and show unresolved comments"
            echo "  push     - Commit all changes with AI-generated message and create/update PR"
            echo "  pull     - Fetch/merge all origin changes to local branch"
        ;;
    esac;;

    # Module Managers
    ser|service) cmd_service "$@" ;;
    pac|package) cmd_package "$@" ;;

    # Utils
    eve|event) cmd_event "$@" ;;
    env|envs)
        # Source projects root cli to load environment variables. example: "source ./cli envs;"
        message 34 "info" "Sourced repo envs"
    ;;

    # Information
    ver|version|--version) cmd_version "$@" ;;
    hel|help|--help|-h)
        cmd_help \
         "    hel|help         " "Display the help message";
    ;;
    *) 
        # informer check-for-updates
        cmd_unknown "$@" 
    ;;
esac
