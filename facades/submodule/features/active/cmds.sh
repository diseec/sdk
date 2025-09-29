#!/bin/bash

# commands.sh - Command handlers for workspace operations

# Show workspace status
sdk_fac_sub_fea_act_status() {
    local config_file="$(cli_ctx config function sdk_fac_con_get_config_file repository)"
    if [ -f "$config_file" ]; then
        stdout "config: $config_file"
        local selected_modules=$(sdk_fac_sub_fea_act_get_selected_modules)
        if [ -n "$selected_modules" ]; then
            active_modules=""
            for module in $selected_modules; do
                if [ -n "$active_modules" ]; then
                    active_modules="$active_modules, $module"
                else
                    active_modules="$module"
                fi
            done
            stdout "Modules: $active_modules"
        else
            stdout -w "No submodules selected in workspace configuration"
        fi
    else
        stdout -w "No workspace configuration found for $D_REPO_NAME"
        echo "Run 'config init' to create one"
    fi
}

# Select submodules for workspace
sdk_fac_sub_fea_act_select() {
    local config_file="$(cli_ctx config function sdk_fac_con_get_config_file repository)"

    # Check if config already exists and has content
    if [ -f "$config_file" ] && [ -s "$config_file" ]; then
        local submodules="$(cli_ctx config function sdk_fac_con_get submodules repository 2>/dev/null)"
        if [ "$submodules" != "null" ] && [ -n "$submodules" ]; then
            if ! confirm "Config already exists. Overwrite?"; then
                stdout -i "Keeping existing configuration"
                return 0
            fi
        fi
    fi

    # TODO: this bit must be extracted from here, this file is internal funcitonality but the followings are a specific settings, have a settings dir keep these in
    # Get available submodules
    available_modules=$(sdk_fac_sub_fea_act_get_available_modules)
    
    if [ -z "$available_modules" ]; then
        stdout -w "No submodules found in .gitmodules"
        return 1
    fi
    
    # Display available submodules and let user select using the select input type
    # Process available modules into proper comma-separated list
    local options=""
    for module in $available_modules; do
        if [ -n "$options" ]; then
            options="$options,$module"
        else
            options="$module"
        fi
    done
    
    
    stdin selection "Select modules:" --type="select" --options="$options"
    
    local selected_modules=""
    if [ "$selection" = "all" ]; then
        selected_modules="$available_modules"
    elif [ "$selection" = "none" ] || [ -z "$selection" ]; then
        selected_modules=""
    else
        # With the select type, selection is the actual module name
        selected_modules="$selection"
    fi

    # Create YAML array from selected modules
    if [ -n "$selected_modules" ]; then
        # Set the submodules array using the YAML format
        cli_ctx config function sdk_fac_con_set submodules "[$(echo $selected_modules | tr ' ' ',')]" repository

        stdout -i "Activated modules: $(echo $selected_modules | tr ' ' ', ')"
    else
        # Set empty array if no modules selected
        cli_ctx config function sdk_fac_con_set submodules "[]" repository
        stdout -w "Cleared all selected modules"
    fi
}
