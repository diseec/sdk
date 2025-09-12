#!/bin/bash

# commands.sh - Command handlers for workspace operations

# Show workspace status
sdk_fac_con_set_act_status() {
    local config_file="$(sdk_fac_con_get_config_file repository)"
    if [ -f "$config_file" ]; then
        logit "config: $config_file"
        local selected_modules=$(sdk_fac_con_set_act_get_selected_modules)
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
        echo "Run 'config init' to create one"
    fi
}

# Select submodules for workspace
sdk_fac_con_set_act_select() {
    local config_file="$(sdk_fac_con_get_config_file repository)"

    # Check if config already exists and has content
    if [ -f "$config_file" ] && [ -s "$config_file" ]; then
        local submodules="$(sdk_fac_con_get submodules repository 2>/dev/null)"
        if [ "$submodules" != "null" ] && [ -n "$submodules" ]; then
            if ! confirm "Config already exists. Overwrite?"; then
                logit -i "Keeping existing configuration"
                return 0
            fi
        fi
    fi

    # TODO: this bit must be extracted from here, this file is internal funcitonality but the followings are a specific settings, have a settings dir keep these in
    # Get available submodules
    available_modules=$(sdk_fac_con_set_act_get_available_modules)
    
    if [ -z "$available_modules" ]; then
        logit -w "No submodules found in .gitmodules"
        return 1
    fi
    
    # Display available submodules and let user select them
    logit -q "Select module numbers to activate"
    i=1
    for module in $available_modules; do
        echo ""$(ansi 35 $i)" $module"
        i=$((i+1))
    done

    input selection "Enter comma-separated (e.g. 1,3) or 'all'" --default="none" --optional

    selected_modules=""
    
    if [ "$selection" = "all" ]; then
        selected_modules="$available_modules"
    elif [ "$selection" = "none" ] || [ -z "$selection" ]; then
        selected_modules=""
    else
        # Parse comma-separated selection
        save_IFS="$IFS"
        IFS=','
        set -- $selection
        IFS="$save_IFS"
        i=1
        for module in $available_modules; do
            for index in "$@"; do
                if [ "$i" -eq "$index" ]; then
                    selected_modules="$selected_modules $module"
                    break
                fi
            done
            i=$((i+1))
        done
    fi
    
    # Create YAML array from selected modules
    if [ -n "$selected_modules" ]; then
        # Create a temporary file for yq processing
        temp_yaml=$(mktemp)
        
        # Initialize YAML file with empty submodules array
        echo "submodules: []" > "$temp_yaml"
        
        # Add each module to the YAML array using yq
        for module in $selected_modules; do
            _yq -i ".submodules += [\"$module\"]" "$temp_yaml"
        done
        
        # Extract the submodules array as YAML
        yaml_array=$(_yq '.submodules' "$temp_yaml")
        
        # Set the submodules array using the YAML format
        cli_ctx config --scope=repository set submodules "$yaml_array"
        
        # Clean up temporary file
        rm "$temp_yaml"

        logit -i "Activated modules: $(echo $selected_modules | tr ' ' ', ')"
    else
        # Set empty array if no modules selected
        cli_ctx config --scope=repository set submodules "[]"
        logit -w "Cleared all selected modules"
    fi

    logit -l "Workspace configuration saved to $config_file"
}
