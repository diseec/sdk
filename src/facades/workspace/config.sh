#!/bin/bash

# ========================================
# WORKSPACE CONFIGURATION COMPATIBILITY
# ========================================
# Provides backward compatibility for workspace configuration functions
# while transitioning to the new centralized configuration system


# =============================================================================
# ENHANCED WORKSPACE FUNCTIONS
# =============================================================================

# Create workspace configuration with new structure
fac_wor_create_config() {
    local config_file="$(fac_con_get_config_file workspace)"

    # Check if workspace config already exists and has content
    if [ -f "$config_file" ] && [ -s "$config_file" ]; then
        local submodules="$(fac_con_get submodules workspace 2>/dev/null)"
        if [ "$submodules" != "null" ] && [ -n "$submodules" ]; then
            printf "$(logger -q "Workspace config already exists. Overwrite? \033[35m[Y/N]\033[0m")"
            stty -echo -icanon time 0 min 1
            response=$(dd bs=1 count=1 2>/dev/null)
            stty echo icanon
            printf "\n"
            
            if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
                logger -i "Keeping existing workspace configuration"
                return 0
            fi
        fi
    fi

    # TODO: this bit must be extracted from here, this file is workspace internal funcitonality but the followings are a specific settings, have a settings dir keep these in
    # Get available submodules
    available_modules=$(fac_wor_get_available_modules)
    
    if [ -z "$available_modules" ]; then
        # logger -w "No submodules found in .gitmodules"
        return 1
    fi
    
    # Display available submodules and let user select them
    logger --ansi="35" --icon="MODULES" "Available submodules:"
    i=1
    for module in $available_modules; do
        echo "  $i) $module"
        i=$((i+1))
    done
    
    echo ""
    logger --ansi="35" --icon="SELECT" "Enter module numbers to include (comma-separated, e.g., 1,3), or 'all' for all submodules, press enter to skip:"
    read selection
    
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
    
    # Clear existing submodules and set empty array
    fac_con_delete submodules workspace 2>/dev/null || true
    
    # Always create empty array first, then add modules
    local config_file="$(fac_con_get_config_file workspace)"
    if command -v _yq >/dev/null 2>&1; then
        _yq -i ".submodules = []" "$config_file"
    else
        # Fallback: ensure file exists and add empty array
        echo "submodules: []" >> "$config_file"
    fi
    
    # Add selected modules to the array
    for module in $selected_modules; do
        fac_con_array_add submodules "$module" workspace
    done

    logger -l "Workspace configuration saved to $config_file"
    logger -i "Activated modules: $(echo $selected_modules | tr ' ' ', ')"
}
