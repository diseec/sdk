#!/bin/bash

source $KIT_SRC_DIR/facades/workspace/index.sh

c=$1; shift; case "$c" in
    ini|init) cmd_workspace_init "$@" ;;
    sel|select) cmd_workspace_select "$@" ;;
    sta|status) cmd_workspace_status "$@" ;;
    con|config) c=$1; shift; case "$c" in
        get) workspace_config_get "$@" ;;
        set) workspace_config_set "$@" ;;
        del|delete|remove) workspace_config_delete "$@" ;;
        array_add) workspace_config_array_add "$@" ;;
        array_remove) workspace_config_array_remove "$@" ;;
        lis|list) workspace_config_keys "$@" ;;
        pri|print) workspace_config_print "$@" ;;
        pat|path) get_workspace_config_path "$@" ;;
        hel|help|--help|-h) display_help "" "" \
            "$(color 30 'Workspace Config Commands')" "" \
            "    get <key.path>                   " "Get value from workspace configuration" \
            "    set <key.path> <value>           " "Set value in workspace configuration" \
            "    del|delete|remove <key.path>     " "Delete key from workspace configuration" \
            "    array_add <key.path> <val>       " "Add item to array in workspace config" \
            "    array_remove <key.path> <val>    " "Remove item from array in workspace config" \
            "    lis|list                         " "List all workspace configuration keys" \
            "    pri|print                        " "Print entire workspace configuration" \
            "" "" "$(color 34 'Examples:')" "" \
            "    cli workspace config set project.name myproject" "" \
            "    cli workspace config get modules" "" \
            "    cli workspace config array_add modules ai-panel" "" \
            "    cli workspace config delete project.description" ""
        ;;
        *) if [ ! -z "$c" ]; then echo "workspace config: Unknown command: '$c'"; fi ;;
    esac ;;
    hel|help|--help|-h) display_help  "" "" \
        "$(color 30 'Workspace Commands')" "" \
        "    ini|init      " "Initialize workspace configuration" \
        "    sel|select    " "Select modules for workspace" \
        "    sta|status    " "Show current workspace configuration" \
        "    con|config    " "Manage workspace configuration (get/set/delete/list)"
    ;;
    *) if [ ! -z "$c" ]; then echo "workspace: Unknown command: '$c'"; fi ;;
esac