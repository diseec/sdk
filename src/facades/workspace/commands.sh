#!/bin/bash

# commands.sh - Command handlers for workspace operations

# Initialize a workspace
cmd_workspace_init() {
    # message 34 "WORKSPACE" "Initializing workspace configuration"
    create_workspace_config
}

# Show workspace status
cmd_workspace_status() {
    local config_file="$(get_workspace_config_path)"
    if [ -f "$config_file" ]; then
        echo "Workspace config: $config_file"
        local selected_modules=$(get_selected_modules)
        if [ -n "$selected_modules" ]; then
            active_modules=""
            for module in $selected_modules; do
                if [ -n "$active_modules" ]; then
                    active_modules="$active_modules, $module"
                else
                    active_modules="$module"
                fi
            done
            echo "Active modules: $active_modules"
        else
            message 33 "INFO" "No modules selected in workspace configuration"
        fi
    else
        message 33 "INFO" "No workspace configuration found for $REPO_NAME"
        echo "Run 'cli workspace init' to create one"
    fi
}

# Select modules for workspace
cmd_workspace_select() {
    message 34 "WORKSPACE" "Select modules for your workspace"
    create_workspace_config
}

# Workspace config command handler
cmd_workspace_config() {
    local operation="$1"; shift
    
    case "$operation" in
        get) workspace_config_get "$@" ;;
        set) workspace_config_set "$@" ;;
        del|delete|remove) workspace_config_delete "$@" ;;
        array_add) workspace_config_array_add "$@" ;;
        array_remove) workspace_config_array_remove "$@" ;;
        lis|list) workspace_config_keys "$@" ;;
        pri|print) workspace_config_print "$@" ;;
        *)
            display_help \
                "" "" \
                "$(color 30 'Workspace Config Commands')" "" \
                "    get <key.path>                   " "Get value from workspace configuration" \
                "    set <key.path> <value>           " "Set value in workspace configuration" \
                "    del|delete|remove <key.path>     " "Delete key from workspace configuration" \
                "    array_add <key.path> <val>       " "Add item to array in workspace config" \
                "    array_remove <key.path> <val>    " "Remove item from array in workspace config" \
                "    lis|list                         " "List all workspace configuration keys" \
                "    pri|print                        " "Print entire workspace configuration" \
                "" "" \
                "$(color 34 'Examples:')" "" \
                "    cli workspace config set project.name myproject" "" \
                "    cli workspace config get modules" "" \
                "    cli workspace config array_add modules ai-panel" "" \
                "    cli workspace config delete project.description" ""
        ;;
    esac
}
