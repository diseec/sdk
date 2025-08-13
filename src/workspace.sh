#!/bin/sh

# workspace.sh - Functions for managing workspace-specific module configurations

# Parse the .gitmodules file to extract available modules
get_available_modules() {
    local gitmodules_file="$ROOT_DIR/.gitmodules"
    
    if [ ! -f "$gitmodules_file" ]; then
        message 41 "ERROR" ".gitmodules file not found at $gitmodules_file"
        return 1
    fi
    
    # Extract module names from the .gitmodules file
    # Format: [submodule "path/to/module"]
    # We want to extract the module name from the path
    grep -E '^\[submodule "' "$gitmodules_file" | sed 's/\[submodule "\(.*\)"\]/\1/' | awk -F'/' '{print $NF}'
}

# Create a workspace configuration by letting the user select modules
create_workspace_config() {
    local config_file="$ROOT_DIR/myworkspace.yaml"
    local template_file="$CLI_ROOT/templates/myworkspace.yaml"
    
    # If myworkspace.yaml already exists, ask for confirmation to overwrite
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
    available_modules=$(get_available_modules)
    
    if [ -z "$available_modules" ]; then
        message 33 "INFO" "No modules found in .gitmodules"
        return 1
    fi
    
    # Display available modules and let the user select them
    message 34 "MODULES" "Available modules:"
    i=1
    for module in $available_modules; do
        echo "  $i) $module"
        i=$((i+1))
    done
    
    echo ""
    message 34 "SELECT" "Enter module numbers to include (comma-separated, e.g., 1,3), or 'all' for all modules:"
    read selection
    
    selected_modules=""
    
    if [ "$selection" = "all" ]; then
        selected_modules="$available_modules"
    else
        # Parse comma-separated selection
        IFS=',' read -ra indices <<< "$selection"
        i=1
        for module in $available_modules; do
            for index in "${indices[@]}"; do
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
    
    message 32 "SUCCESS" "Workspace configuration saved to $config_file"
    message 34 "MODULES" "Selected modules: $(echo $selected_modules | tr ' ' ', ')"
}

# Get the list of selected modules from myworkspace.yaml
get_selected_modules() {
    local config_file="$ROOT_DIR/myworkspace.yaml"
    
    if [ ! -f "$config_file" ]; then
        # If myworkspace.yaml doesn't exist, create it
        message 33 "INFO" "Workspace configuration not found. Creating..."
        create_workspace_config
    fi
    
    # Extract module names from myworkspace.yaml
    grep -E '^  - ' "$config_file" | sed 's/^  - //'
}

# Get the module path from a module name
get_module_path() {
    local module_name="$1"
    
    if [ -z "$module_name" ]; then
        return 1
    fi
    
    # Extract the module path from .gitmodules
    local module_path=$(grep -A2 "\[submodule \".*$module_name\"\]" "$ROOT_DIR/.gitmodules" | grep "path = " | sed 's/^[[:space:]]*path = //')
    
    echo "$module_path"
}

# Check if a module is selected in the workspace configuration
is_module_selected() {
    local module_name="$1"
    local selected_modules=$(get_selected_modules)
    
    for selected_module in $selected_modules; do
        if [ "$selected_module" = "$module_name" ]; then
            return 0  # True
        fi
    done
    
    return 1  # False
}

# Run a command for each selected module
foreach_selected_module() {
    local command="$1"
    local selected_modules=$(get_selected_modules)
    
    if [ -z "$selected_modules" ]; then
        message 33 "INFO" "No modules selected in workspace configuration"
        return 1
    fi
    
    for module in $selected_modules; do
        local module_path=$(get_module_path "$module")
        
        if [ -n "$module_path" ]; then
            message 34 "$module" "Running command: $command"
            (cd "$ROOT_DIR/$module_path" && eval "$command")
        else
            message 41 "ERROR" "Module path not found for $module"
        fi
    done
}

# Run a callback function for each selected module
# Usage: foreach_selected_module_with_callback callback_function [additional_args...]
foreach_selected_module_with_callback() {
    local callback_function="$1"
    shift
    local selected_modules=$(get_selected_modules)
    
    if [ -z "$selected_modules" ]; then
        message 33 "INFO" "No modules selected in workspace configuration"
        return 1
    fi
    
    for module in $selected_modules; do
        local module_path=$(get_module_path "$module")
        
        if [ -n "$module_path" ]; then
            "$callback_function" "$module" "$module_path" "$@"
        else
            message 41 "ERROR" "Module path not found for $module"
        fi
    done
}

# Initialize a workspace
cmd_workspace_init() {
    # message 34 "WORKSPACE" "Initializing workspace configuration"
    create_workspace_config
}

# Get a space-separated list of services based on selected modules
get_services_filter() {
    local selected_modules=$(get_selected_modules)
    local services_filter=""
    local docker_compose_file="$ROOT_DIR/docker-compose.yaml"
    
    # Check if docker-compose file exists
    if [ ! -f "$docker_compose_file" ]; then
        # Try alternative filename
        docker_compose_file="$ROOT_DIR/docker-compose.yml"
        if [ ! -f "$docker_compose_file" ]; then
            message 41 "ERROR" "Docker Compose file not found"
            return 1
        fi
    fi
    
    if [ -n "$selected_modules" ]; then
        for module in $selected_modules; do
            # Check if the module exists as a service in docker-compose file
            if grep -q "^[[:space:]]*$module:[[:space:]]*$" "$docker_compose_file" || 
               grep -q "^[[:space:]]*$module:" "$docker_compose_file"; then
                services_filter="$services_filter $module"
            fi
        done
    fi
    
    echo "$services_filter"
}

# Show workspace status
cmd_workspace_status() {
    message 34 "WORKSPACE" "Current workspace configuration"
    
    local config_file="$ROOT_DIR/myworkspace.yaml"
    if [ -f "$config_file" ]; then
        local selected_modules=$(get_selected_modules)
        message 34 "MODULES" "Selected modules:"
        for module in $selected_modules; do
            echo "  - $module"
        done
    else
        message 33 "INFO" "No workspace configuration found"
    fi
}

# Select modules for workspace
cmd_workspace_select() {
    message 34 "WORKSPACE" "Select modules for your workspace"
    create_workspace_config
}
