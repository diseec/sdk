#!/bin/bash

# workspace/index.sh - Main workspace module that sources all workspace functionality


# This file serves as the main entry point for workspace functionality
# All functions from the individual modules are now available when this file is sourced

main() {
    # Source config facade to get YAML utilities
    . $KIT_SRC_DIR/facades/config.sh

    # Source all workspace modules
    . $KIT_SRC_DIR/facades/workspace/config.sh
    . $KIT_SRC_DIR/facades/workspace/modules.sh
    . $KIT_SRC_DIR/facades/workspace/yaml-api.sh
    . $KIT_SRC_DIR/facades/workspace/fallback.sh
    . $KIT_SRC_DIR/facades/workspace/commands.sh

    c=$1; shift; case "$c" in
        ini|init) cmd_workspace_init ;;
        sel|select) cmd_workspace_select ;;
        sta|status) cmd_workspace_status ;;
        con|config) cmd_workspace_config "$@" ;;
        fsm|foreach-selected-module-run) foreach_selected_module_with_callback "$@" ;;
        *) display_help  "" "" \
            "$(color 30 'Workspace Commands')" "" \
            "    ini|init      " "Initialize workspace configuration" \
            "    sel|select    " "Select modules for workspace" \
            "    sta|status    " "Show current workspace configuration" \
            "    con|config    " "Manage workspace configuration (get/set/delete/list)"
        ;;
    esac 
}