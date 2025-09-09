#!/bin/bash

# commands.sh - Command handlers for workspace operations

# Initialize a workspace
sdk_fac_con_opt_act_init() {
    if [ ! -f "$(cli_ctx config function sdk_fac_con_get_config_file repository)" ] && [ "$D_HAS_SUBMODULES" = "true" ]; then
        logit -l "Initializing workspace configuration..."
        sdk_fac_con_opt_act_create_config
    fi
}

# Show workspace status
sdk_fac_con_opt_act_status() {
    local config_file="$(cli_ctx config function sdk_fac_con_get_config_file repository)"
    if [ -f "$config_file" ]; then
        logit "config: $config_file"
        local selected_modules=$(sdk_fac_con_opt_act_get_selected_modules)
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
        logit -w "No workspace configuration found for $D_REPO_NAME"
        echo "Run 'cli config init' to create one"
    fi
}

# Select submodules for workspace
sdk_fac_con_opt_act_select() {
    local submodule_name="$1"
    
    if [ -n "$submodule_name" ]; then
        # Non-interactive mode: add the specified submodule directly
        logit -l "Adding submodule '$submodule_name' to workspace configuration..."
        
        # Add to context.submodules array
        cli_ctx config function sdk_fac_con_set "context.submodules" "$submodule_name" "context" "true"
        
        logit -l "Submodule '$submodule_name' added to workspace configuration"
    else
        # Interactive mode: show selection UI
        logit --ansi="34" --icon="Submodules" "Active submodules for your workspace"
        sdk_fac_con_opt_act_create_config
    fi
}
