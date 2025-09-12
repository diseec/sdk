#!/bin/bash

# ========================================
# WORKSPACE CONFIGURATION COMPATIBILITY
# ========================================
# Provides backward compatibility for configuration functions
# while transitioning to the new centralized configuration system


# =============================================================================
# ENHANCED WORKSPACE FUNCTIONS
# =============================================================================

# Create configuration with new structure
sdk_fac_con_set_act_create_config() {
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
    logit --ansi="35" --icon="MODULES" "Available submodules:"
    i=1
    for module in $available_modules; do
        echo "  $i) $module"
        i=$((i+1))
    done
    
    # Use the input function for better UX
    selection=$(input "Enter module numbers to include (comma-separated, e.g., 1,3), or 'all' for all submodules:" --optional)
    
    selected_modules=""
    
    if [ "$selection" = "all" ]; then
        selected_modules="$available_modules"
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
    else
        # Set empty array if no modules selected
        cli_ctx config --scope=repository set submodules "[]"
    fi

    logit -l "Workspace configuration saved to $config_file"
    logit -i "Activated modules: $(echo $selected_modules | tr ' ' ', ')"
}
