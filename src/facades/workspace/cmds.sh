#!/bin/bash

# commands.sh - Command handlers for workspace operations

# Initialize a workspace
fac_wor_init() {
    # message 34 "WORKSPACE" "Initializing workspace configuration"
    fac_wor_create_config
}

# Show workspace status
fac_wor_status() {
    local config_file="$(fac_wor_get_config_path)"
    if [ -f "$config_file" ]; then
        echo "Workspace config: $config_file"
        local selected_modules=$(fac_wor_get_selected_modules)
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
fac_wor_select() {
    message 34 "WORKSPACE" "Select modules for your workspace"
    fac_wor_create_config
}
