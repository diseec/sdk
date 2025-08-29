#!/bin/bash

# config.sh - Functions for managing workspace configuration files

# Get the workspace configuration file path for the current repository
fac_wor_get_config_path() {
    # Create repository-specific directory if it doesn't exist
    local repo_dir="$ORG_DIR/workspaces/$REPO_NAME"
    if [ ! -d "$repo_dir" ]; then
        mkdir -p "$repo_dir"
    fi
    
    # Use config.yaml as the standard config file name
    echo "$repo_dir/config.yaml"
}

# Get the workspace configuration file for the current repository
fac_wor_get_config_file() {
    local config_file="$(fac_wor_get_config_path)"
    if [ ! -f "$config_file" ]; then
        local repo_dir="$ORG_DIR/workspaces/$REPO_NAME"
        mkdir -p "$repo_dir"
        echo "modules: []" > "$config_file"
    fi
    echo "$config_file"
}

# Create a workspace configuration by letting the user select modules
fac_wor_create_config() {
    local config_file="$(fac_wor_get_config_path)"
    local template_file="$KIT_DIR/templates/myworkspace.yaml"
    
    # If workspace config file already exists, ask for confirmation to overwrite
    if [ -f "$config_file" ]; then
        printf "$(message 45 "?" "Workspace config already exists. Overwrite? \033[35m[y/n]\033[0m")"
        stty -echo -icanon time 0 min 1
        response=$(dd bs=1 count=1 2>/dev/null)
        stty echo icanon
        printf "\n"
        
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            message 33 "INFO" "Keeping existing workspace configuration"
            return 0
        fi
    fi
    
    # Copy the template file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        if [ -f "$template_file" ]; then
            cp "$template_file" "$config_file"
        else
            # Create a basic template if the template file doesn't exist
            echo "modules: []" > "$config_file"
        fi
    fi
    
    # Get available modules
    available_modules=$(fac_wor_get_available_modules)
    
    if [ -z "$available_modules" ]; then
        message 33 "INFO" "No modules found in .gitmodules"
        return 1
    fi
    
    # Display available modules and let the user select them
    message 44 "MODULES" "Available modules:"
    i=1
    for module in $available_modules; do
        echo "  $i) $module"
        i=$((i+1))
    done
    
    echo ""
    message 44 "SELECT" "Enter module numbers to include (comma-separated, e.g., 1,3), or 'all' for all modules, press enter to skip:"
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
    
    # Write the selection to myworkspace.yaml
    echo "modules:" > "$config_file"
    for module in $selected_modules; do
        echo "  - $module" >> "$config_file"
    done
    
    message 42 "OKEY" "Workspace configuration saved to $config_file"
    message 34 "MODULES" "Selected modules: $(echo $selected_modules | tr ' ' ', ')"
}
