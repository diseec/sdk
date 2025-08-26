#!/bin/bash

# modules.sh - Functions for managing git submodules and module discovery

# Get the list of selected modules from workspace config
get_selected_modules() {
    local config_file="$(get_workspace_config_path)"

    if [ ! -f "$config_file" ]; then
        # If workspace config doesn't exist, just return empty (no modules selected)
        # This is a valid state - user doesn't have to select any modules
        echo ""
        return 0
    fi
    
    # Extract module names from workspace config
    grep -E '^  - ' "$config_file" | sed 's/^  - //'
}

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
        # No modules selected is a valid state - just return success
        message 33 "INFO" "No modules selected in workspace configuration"
        return 0
    fi
    
    for module in $selected_modules; do
        local module_path=$(get_module_path "$module")
        
        if [ -n "$module_path" ]; then
            message 34 "$module" "Running command: $command"
            (cd "$ROOT_DIR/$module_path" && eval "$command")
        else
            message 43 "WARNING" "Module path not found for $module, skipping"
        fi
    done
}

# Run a callback function for each selected module
# Usage: "$CLI" workspace foreach-selected-module-run callback_function [additional_args...]
foreach_selected_module_with_callback() {
    if [ $IS_MONOREPO != "true" ]; then return; fi
    local callback_function="$1"
    shift
    local selected_modules=$(get_selected_modules)

    if [ -z "$selected_modules" ]; then
        # No modules selected is a valid state - just return success
        message 33 "INFO" "No modules selected in workspace configuration"
        return 0
    fi
    
    for module in $selected_modules; do
        local module_path=$(get_module_path "$module")
        if [ -n "$module_path" ]; then
            "$callback_function" "$module" "$module_path" "$@"
        else
            message 43 "WARNING" "Module path not found for $module, skipping"
        fi
    done
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
            # If no docker-compose file exists, just return empty string
            # This is not an error condition
            return 0
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
