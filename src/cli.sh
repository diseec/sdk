#!/bin/sh

. $KIT_DIR/index.sh;

c=$1; shift; case $c in

    x) echo 'dddd' ;;
    env|envs) message 34 "INFO" "Sourced repo envs" ;; # Source projects root cli to load environment variables. example: "source ./cli envs;"
    kit) export TO_MOUNT_DIR="$ROOT_DIR"; cd $KIT_DIR; D "$@" ;;

    ######################## SETUP CMDS ########################

    ins|install)
        c=$1; if [ -n "$c" ]; then shift; else . $CLI install project; return 0; fi
        case "$c" in
            pro|project) . $KIT_SRC_DIR/install/project.sh "$@" ;;
            pre|prettier) . $KIT_SRC_DIR/install/prettier.sh "$@" ;;
            glo|globally) . $KIT_SRC_DIR/install/globally.sh "$@" ;;
            # *) define helps ;;
        esac ;;
    upd|update) . $KIT_SRC_DIR/cmds/update.sh; cmd_update "$@" ;;

    ######################## DEV CMDS ########################

    dev|develop) . $CLI docker compose up-development "$@" ;;
    run) . $CLI docker compose execute "$REPO_NAME" "$@" ;;
    exe|execute) . $CLI docker compose execute "$@" ;;
    bui|build) . $CLI docker compose build-parallel "$@" ;;
    she|shell) . $CLI run /bin/bash "$@" ;;
    pul|pull) . $CLI git pull "$@" ;;
    pus|push) . $CLI git push "$@" ;;
    for|format) . $KIT_SRC_DIR/cmds/format.sh "**/*.{js,jsx,ts,tsx,json,css,scss,md}" ;;
    tes|test) . $KIT_SRC_DIR/cmds/test.sh "$@" ;;

    ######################## GROUP CMDS ########################

    doc|docker) c=$1; shift; case $c in
        com|compose) c=$1; shift; case $c in
            upd|up-development) . $KIT_SRC_DIR/cmds/docker/up-development.sh "$@" ;;
            upp|up-production) . $KIT_SRC_DIR/cmds/docker/up-production.sh "$@" ;;
            exe|execute) . $KIT_SRC_DIR/cmds/docker/execute.sh "$@" ;;
            bui|build-parallel) _docker compose build --parallel "$@" ;;
            # hel|help|--help|-h) help docs comes here ;;
            *) _docker compose "$@" ;;
        esac ;;
        # hel|help|--help|-h) help docs comes here ;;
        *) _docker "$@" ;;
    esac ;;

    git) . $KIT_SRC_DIR/cmds/git.sh; c=$1; shift; case "$c" in
        sta|status)
            . $CLI inform forbid-dev-on-main
            . $CLI inform summary-branch-status
            cmd_git_check_pr_status "$@"
        ;;
        pus|push) cmd_git_create_or_update_pr "$@" ;;
        pul|pull) cmd_git_pull "$@" ;;
        rel|release) cmd_git_release "$@" ;;
        *)
            message 33 "GIT" "Available git commands:"
            echo "  status   - Check status of current branch's PR and show unresolved comments"
            echo "  push     - Commit all changes with AI-generated message and create/update PR"
            echo "  pull     - Fetch/merge all origin changes to local branch"
        ;;
    esac;;

    sec|secrets) . $KIT_SRC_DIR/cmds/secrets.sh; c=$1; shift; case $c in
        ini|init) cmd_secret_init "$@" ;;
        set|set-key) cmd_secret_set_key "$@" ;;
        res|reset-key) cmd_secret_reset_key "$@" ;;
        key|show-key) cmd_secret_show_key "$@" ;;
        add) cmd_secret_add_secret "$@" ;;
        get|get-all) cmd_secret_get_all_secrets "$@" ;;
        sho|show) cmd_secret_show_secrets "$@" ;;
        lis|list) cmd_secret_list_secrets "$@" ;;
        cle|clear) cmd_secret_clear_secrets "$@" ;;
        deb|debug) cmd_secret_debug "$@" ;;
        rem|remove|rm) cmd_secret_remove_secret "$@" ;;
        *)
            message 33 "SECRETS" "Available secrets commands:"
            echo "  ini|init               - Initialize encryption key (auto-generated)"
            echo "  set|set-key            - Set encryption key manually"
            echo "  res|reset-key          - Generate new encryption key and re-encrypt all secrets"
            echo "  key|show-key           - Display current encryption key"
            echo "  add                    - Add a new secret"
            echo "  sho|show               - Display all secrets in readable format"
            echo "  get|get-all            - Export all secrets as environment variables"
            echo "  lis|list               - List all secret names"
            echo "  cle|clear              - Remove all secrets (requires confirmation)"
            echo "  debug                  - Test encryption/decryption functionality"
            echo "  rem|remove <name>      - Remove a secret"
            echo ""
            message 34 "INFO" "Secrets are encrypted with AES-256-CBC using auto-generated keys"
            echo ""
            message 33 "IMPORTANT" "If secrets exist but no key is configured, you must:"
            echo "  1. Set the original key manually: secrets set-key"
            echo "  2. Clear all secrets: secrets clear"
        ;;
    esac;;

    ######################## SUBMODULES ########################

    ser|service) . $KIT_SRC_DIR/cmds/services.sh "$@" ;;
    pac|package) . $KIT_SRC_DIR/cmds/packages.sh "$@" ;;
    wor|workspace) . $KIT_SRC_DIR/cmds/workspace.sh; c=$1; shift; case "$c" in
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

    ######################## API ########################

    api) c=$1; shift; case "$c" in
        v1) c=$1; shift; case "$c" in
            install) . $CLI install "$@" ;;
        esac ;;
        # *) write helps here ;;
    esac ;;

    ######################## FACADES ########################

    saf|safe)
        $CLI $KIT_NAME execute $KIT_NAME bash -c "D "$@""
        ;;
    # saf|safe) . $CLI $KIT_NAME run $CLI "$@" ;;
    eve|event) . $KIT_SRC_DIR/facades/event.sh "$@" ;;
    con|config) . $KIT_SRC_DIR/facades/config.sh; c=$1; shift; case "$c" in
        get) config_get "$@" ;;
        set) config_set "$@" ;;
        delete) config_delete "$@" ;;
        array_add) config_array_add "$@" ;;
        array_remove) config_array_remove "$@" ;;
        list) config_keys "$@" ;;
        print) config_print "$@" ;;
        # *)  ;;
    esac ;;

    ######################## INFORMATION ########################

    sta|status)         
        . $CLI version
        . $CLI workspace status
        . $CLI git status
        . $CLI inform check-for-updates
    ;;
    inf|inform) c=$1; shift; case $c in
        # check-network-status) ;;
        forbid-dev-on-main) . $KIT_SRC_DIR/informs/forbid-dev-on-main.sh "$@" ;;
        summary-branch-status) . $KIT_SRC_DIR/informs/summary-branch-status.sh "$@" ;;
        check-for-updates) . $KIT_SRC_DIR/informs/check-for-updates.sh "$@" ;;
        *)
            message 33 "INFORM" "Available inform commands:"
            echo "  forbid-dev-on-main    - Warn if on 'main' branch"
            echo "  summary-branch-status - Show local vs remote branch status"
            echo "  check-for-updates     - Check for updates and notify"
        ;;
    esac ;;
    ver|version|--version) message 40 "v$VERSION" "DISEEC DevOps CLI — Automation Toolkit" ;;
    hel|help|--help|-h)
        display_help \
            "" "" \
            "$(color 33 'Usage:')" "" \
            "$(color 32 '    command [options] [arguments]\n')" "" \
            "$(color 33 'Base Commands:')" "" \
            "    ins|install      "  "Install the dependencies" \
            "    upd|update       "  "Sync project with latest updates" \
            "    sta|status       "  "Show project status" \
            "    pul|pull         "  "Pull and merge latest changes from repository. Alias to 'cli git pull'" \
            "    pus|push         "  "Automated commit->push->pr process with AI generated message. Alias to 'cli git push'" \
            "    dev              "  "Start the development server" \
            "    pro              "  "Start the production server" \
            "    bui|build        "  "Build the image push to registry" \
            "    run              "  "Run a command in fresh instance, usage: run <command>" \
            "    exe|exec         "  "Run a command in a service container, usage: exec <service-name> <command>" \
            "    she|shell        "  "Start a shell" \
            "    tes|test         "  "Run the tests in production mode, see: test -h" \
            "    for|format       "  "Check if Prettier exists and run formatting on codebase" \
            "    git              "  "Git management commands run: cli git help" \
            "    $KIT_NAME           "  "Run a command in SDK image, usage: $KIT_NAME <command>" \
            "    ser|service      "  "Run a command in a service, usage: cli service <command>" \
            "    pac|package      "  "Run a command in a package, usage: cli package <command>" \
            "    wor|workspace    "  "Manage workspace configuration [init|select|status]" \
            "    sec|secrets      "  "Manage secrets [init|show-key|regenerate-key|add|get-all|list|remove]" \
            "    env|envs         "  "All exported envs, source project cli to load them!" \
            "    ver|version      "  "Show the current kit version" \
            "    hel|help         "  "Display the help message" \
            "$@"
    ;;
    *)
        if [ ! -z "$command" ]; then message 41 "error" "Unknown command: '$command'"; fi
        . $CLI help; exit 1;
    ;;
esac
