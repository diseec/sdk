#!/bin/bash

# commands.sh - Command handlers for workspace operations

# Initialize a workspace
fac_wor_init() {
    # logit 34 "WORKSPACE" "Initializing workspace configuration"
    fac_wor_create_config
}

# Show workspace status
fac_wor_status() {
    local config_file="$(fac_con_get_config_file workspace)"
    if [ -f "$config_file" ]; then
        logit "config: $config_file"
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
            logit "Modules: $active_modules"
        else
            logit -w "No submodules selected in workspace configuration"
        fi
    else
        logit -w "No workspace configuration found for $REPO_NAME"
        echo "Run 'cli workspace init' to create one"
    fi
}

# Select submodules for workspace
fac_wor_select() {
    logit --ansi="34" --icon="WORKSPACE" "Select submodules for your workspace"
    fac_wor_create_config
}
