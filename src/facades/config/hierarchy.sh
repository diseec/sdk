#!/bin/bash

# ========================================
# CONFIGURATION HIERARCHY AND RESOLUTION
# ========================================
# Handles configuration value resolution with scope precedence

# =============================================================================
# CONFIGURATION VALUE RESOLUTION
# =============================================================================

# Get configuration value with hierarchy resolution
# Searches through scopes in order of precedence: project -> workspace -> user -> global
fac_con_get() {
    set -e
    local key_path="$1"
    local specific_scope="$2"  # Optional: if specified, only check this scope
    
    # Validate key path
    fac_con_validate_key_path "$key_path" || return 1
    
    # If specific scope is provided, only check that scope
    if [ -n "$specific_scope" ]; then
        fac_con_validate_scope "$specific_scope" || return 1
        local config_file="$(fac_con_ensure_config_file "$specific_scope")"
        fac_con_yaml_get "$config_file" "$key_path"
        return $?
    fi
    
    # Search through scopes in order of precedence
    for scope in $CONFIG_SCOPES; do
        local config_file="$(fac_con_get_config_file "$scope")"
        
        # Skip if config file doesn't exist for this scope
        if [ ! -f "$config_file" ]; then
            continue
        fi
        
        local value="$(fac_con_yaml_get "$config_file" "$key_path")"
        
        # Return the first non-null value found
        if [ "$value" != "null" ] && [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    done
    
    # No value found in any scope
    echo "null"
    return 1
}

# Set configuration value in specified scope (defaults to workspace)
fac_con_set() {
    set -e
    local key_path="$1"
    local value="$2"
    local scope="${3:-workspace}"  # Default to workspace scope
    
    # Validate inputs
    fac_con_validate_key_path "$key_path" || return 1
    fac_con_validate_scope "$scope" || return 1
    
    if [ -z "$value" ]; then
        message 41 "!" "Configuration value cannot be empty"
        return 1
    fi
    
    # Ensure config file exists and set value
    local config_file="$(fac_con_ensure_config_file "$scope")"
    fac_con_yaml_set "$config_file" "$key_path" "$value"
    
    echo "Set '$key_path' = '$value' in '$scope' scope"
}

# Delete configuration key from specified scope (defaults to workspace)
fac_con_delete() {
    set -e
    local key_path="$1"
    local scope="${2:-workspace}"  # Default to workspace scope
    
    # Validate inputs
    fac_con_validate_key_path "$key_path" || return 1
    fac_con_validate_scope "$scope" || return 1
    
    local config_file="$(fac_con_get_config_file "$scope")"
    
    if [ ! -f "$config_file" ]; then
        message 43 "!" "Configuration file does not exist for scope: $scope"
        return 1
    fi
    
    fac_con_yaml_delete "$config_file" "$key_path"
    echo "Deleted $key_path from $scope scope"
}

# =============================================================================
# ARRAY OPERATIONS
# =============================================================================

# Add value to configuration array
fac_con_array_add() {
    set -e
    local key_path="$1"
    local value="$2"
    local scope="${3:-workspace}"  # Default to workspace scope
    
    # Validate inputs
    fac_con_validate_key_path "$key_path" || return 1
    fac_con_validate_scope "$scope" || return 1
    
    if [ -z "$value" ]; then
        message 41 "!" "Array value cannot be empty"
        return 1
    fi
    
    # Ensure config file exists and add to array
    local config_file="$(fac_con_ensure_config_file "$scope")"
    fac_con_yaml_array_add "$config_file" "$key_path" "$value"

    echo "Added '$value' to '$key_path' array in '$scope' scope"
}

# Remove value from configuration array
fac_con_array_remove() {
    set -e
    local key_path="$1"
    local value="$2"
    local scope="${3:-workspace}"  # Default to workspace scope
    
    # Validate inputs
    fac_con_validate_key_path "$key_path" || return 1
    fac_con_validate_scope "$scope" || return 1
    
    if [ -z "$value" ]; then
        message 41 "!" "Array value cannot be empty"
        return 1
    fi
    
    local config_file="$(fac_con_get_config_file "$scope")"
    
    if [ ! -f "$config_file" ]; then
        message 43 "!" "Configuration file does not exist for scope: $scope"
        return 1
    fi
    
    fac_con_yaml_array_remove "$config_file" "$key_path" "$value"
    echo "Removed '$value' from '$key_path' array in '$scope' scope"
}

# =============================================================================
# CONFIGURATION INTROSPECTION
# =============================================================================

# List all configuration keys from all scopes
fac_con_list_keys() {
    set -e
    local scope="$1"  # Optional: if specified, only list keys from this scope
    
    if [ -n "$scope" ]; then
        fac_con_validate_scope "$scope" || return 1
        local config_file="$(fac_con_get_config_file "$scope")"
        
        if [ -f "$config_file" ]; then
            echo "Keys in '$scope' scope:"
            fac_con_yaml_keys "$config_file" | sed 's/^/  /'
        else
            echo "No configuration file found for '$scope' scope"
        fi
    else
        echo "Configuration keys by scope:"
        for scope in $CONFIG_SCOPES; do
            local config_file="$(fac_con_get_config_file "$scope")"
            
            if [ -f "$config_file" ]; then
                echo ""
                echo "[$scope]"
                fac_con_yaml_keys "$config_file" | sed 's/^/  /'
            fi
        done
    fi
}

# Show configuration value resolution path
fac_con_which() {
    set -e
    local key_path="$1"
    
    fac_con_validate_key_path "$key_path" || return 1
    
    echo "Configuration resolution for '$key_path':"
    
    local found_value=""
    local found_scope=""
    
    for scope in $CONFIG_SCOPES; do
        local config_file="$(fac_con_get_config_file "$scope")"
        
        if [ -f "$config_file" ]; then
            local value="$(fac_con_yaml_get "$config_file" "$key_path")"
            
            if [ "$value" != "null" ] && [ -n "$value" ]; then
                if [ -z "$found_value" ]; then
                    found_value="$value"
                    found_scope="$scope"
                    echo "  ✔ [$scope] $value (ACTIVE)"
                else
                    echo "  - [$scope] $value (overridden)"
                fi
            else
                echo "  - [$scope] (not set)"
            fi
        else
            echo "  - [$scope] (no config file)"
        fi
    done
    
    if [ -n "$found_value" ]; then
        echo ""
        echo "Resolved value: $found_value (from $found_scope scope)"
    else
        echo ""
        echo "No value found for '$key_path'"
    fi
}

# Print configuration for a specific scope
fac_con_print() {
    set -e
    local scope="${1:-all}"  # Default to all scopes
    
    if [ "$scope" = "all" ]; then
        echo "Complete configuration hierarchy:"
        for scope in $CONFIG_SCOPES; do
            local config_file="$(fac_con_get_config_file "$scope")"
            
            echo ""
            echo "[$scope] - $config_file"
            if [ -f "$config_file" ]; then
                cat "$config_file" | sed 's/^/  /'
            else
                echo "  (no configuration file)"
            fi
        done
    else
        fac_con_validate_scope "$scope" || return 1
        local config_file="$(fac_con_ensure_config_file "$scope")"
        
        echo "Configuration for $scope scope:"
        echo "File: $config_file"
        echo ""
        cat "$config_file"
    fi
}
