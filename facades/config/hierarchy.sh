#!/bin/bash

# ========================================
# CONFIGURATION HIERARCHY AND RESOLUTION
# ========================================
# Handles configuration value resolution with scope precedence

# =============================================================================
# CONFIGURATION VALUE RESOLUTION
# =============================================================================

# Get configuration value with hierarchy resolution
# Searches through scopes in order of precedence: context -> repository -> user
sdk_fac_con_get() {
    set -e
    local key_path="$1"
    local specific_scope="$2"  # Optional: if specified, only check this scope

    # Validate key path
    sdk_fac_con_validate_key_path "$key_path" || return 1
    
    # If specific scope is provided, only check that scope
    if [ -n "$specific_scope" ]; then
        sdk_fac_con_validate_scope "$specific_scope" || return 1
        local config_file="$(sdk_fac_con_get_config_file "$specific_scope")"
        
        # Check if config file exists
        if [ ! -f "$config_file" ]; then
            echo "Configuration key '$key_path' not found in $specific_scope scope" >&2
            return 1
        fi
        
        local value="$(_yq eval ".${key_path}" "$config_file" 2>/dev/null)"
        
        # Check if key was not found
        if [ "$value" = "null" ] || [ -z "$value" ]; then
            echo "Configuration key '$key_path' not found in $specific_scope scope" >&2
            return 1
        fi
        
        # Return raw YAML value - no JSON conversion
        echo "$value"
        return 0
    fi
    
    # Search through scopes in order of precedence
    for scope in $CONFIG_SCOPES; do
        local config_file="$(sdk_fac_con_get_config_file "$scope")"
        
        # Skip if config file doesn't exist for this scope
        if [ ! -f "$config_file" ]; then
            continue
        fi
        
        local value="$(_yq eval ".${key_path}" "$config_file" 2>/dev/null)"
        
        # Return the first non-null value found
        if [ "$value" != "null" ] && [ -n "$value" ]; then
            # Return raw YAML value - no JSON conversion
            echo "$value"
            return 0
        fi
    done
    
    # No value found in any scope
    echo "Configuration key '$key_path' not found" >&2
    return 1
}

# Set configuration value in specified scope (defaults to $DEFAULT_SCOPE)
# Enhanced to handle both scalar values and arrays
sdk_fac_con_set() {
    set -e
    local key_path="$1"
    local value="$2"
    local scope="${3:-$DEFAULT_SCOPE}"  # Default to $DEFAULT_SCOPE scope
    local is_array="${4:-false}"        # Optional: specify if value should be treated as array element
    
    # Validate inputs
    sdk_fac_con_validate_key_path "$key_path" || return 1
    sdk_fac_con_validate_scope "$scope" || return 1
    
    if [ -z "$value" ]; then
        logit -e "Configuration value cannot be empty"
        return 1
    fi
    
    # Ensure config file exists
    local config_file="$(sdk_fac_con_get_config_file "$scope")"
    
    # Check if this is an array operation
    if [ "$is_array" = "true" ]; then
        # Handle as array operation - add value to array
        sdk_fac_con_yaml_array_add "$config_file" "$key_path" "$value"
        logit -l "Added '$value' to '$key_path' array in '$scope' scope"
    else
        # Handle as scalar operation - set value
        sdk_fac_con_yaml_set "$config_file" "$key_path" "$value"
        logit -l "Set '$key_path' = '$value' in '$scope' scope"
    fi
    
    return 0
}

# Delete configuration key or array element from specified scope (defaults to $DEFAULT_SCOPE)
# Enhanced to handle both keys and array elements
sdk_fac_con_delete() {
    set -e
    local key_path="$1"
    local value="$2"          # Optional: if provided, remove this value from array
    local scope="${3:-$DEFAULT_SCOPE}"  # Default to $DEFAULT_SCOPE scope
    
    # Validate inputs
    sdk_fac_con_validate_key_path "$key_path" || return 1
    sdk_fac_con_validate_scope "$scope" || return 1
    
    local config_file="$(sdk_fac_con_get_config_file "$scope")"
    
    if [ ! -f "$config_file" ]; then
        logit -w "Configuration file does not exist for scope: $scope"
        return 1
    fi
    
    # First check if the key exists before attempting to delete
    local key_exists
    key_exists=$(_yq eval ".${key_path} // \"__key_not_found__\"" "$config_file" 2>/dev/null)
    
    if [ "$key_exists" = "__key_not_found__" ] || [ -z "$key_exists" ] || [ "$key_exists" = "null" ]; then
        # Key doesn't exist, but we'll still consider this a success for idempotency
        logit -l "Deleted '$key_path' from '$scope' scope"
        return 0
    fi
    
    # Check if this is an array element removal
    if [ -n "$value" ]; then
        # Remove value from array
        sdk_fac_con_yaml_array_remove "$config_file" "$key_path" "$value"
        logit -l "Removed '$value' from '$key_path' array in '$scope' scope"
    else
        # Delete entire key
        sdk_fac_con_yaml_delete "$config_file" "$key_path"
        logit -l "Deleted '$key_path' from '$scope' scope"
    fi
    
    return 0
}

# =============================================================================
# CONFIGURATION SUMMARY AND STATUS
# =============================================================================

# Show configuration summary across all scopes
sdk_fac_con_summary() {
    echo "Configuration Summary:"
    echo ""
    
    for scope in $CONFIG_SCOPES; do
        local config_file="$(sdk_fac_con_get_config_file "$scope")"
        local scope_display=$(echo "$scope" | tr '[:lower:]' '[:upper:]')
        
        echo "[$scope_display SCOPE]"
        echo "  File: $config_file"
        
        if [ -f "$config_file" ] && [ -s "$config_file" ]; then
            local key_count=$(sdk_fac_con_yaml_keys "$config_file" | wc -l | xargs)
            echo "  Status: Configured ($key_count keys)"
        else
            echo "  Status: Empty or not configured"
        fi
        echo ""
    done
}

# =============================================================================
# CONFIGURATION INITIALIZATION
# =============================================================================

# Initialize configuration system - create all config files
sdk_fac_con_init() {
    local initialized_files=()
    
    # Initialize config files for all scopes
    for scope in $CONFIG_SCOPES; do
        local config_file="$(sdk_fac_con_get_config_file "$scope")"
        if [ -f "$config_file" ] && [ -s "$config_file" ]; then
            # File exists and has content - skip
            continue
        else
            # Create or initialize empty file
            echo "{}" > "$config_file"
            initialized_files+=("$scope")
        fi
    done
    
    if [ ${#initialized_files[@]} -gt 0 ]; then
        local scopes_list=$(IFS=', '; echo "${initialized_files[*]}")
        echo "Configuration initialized for scopes: $scopes_list"
    else
        echo "Configuration already initialized"
    fi
    
    return 0
}

# =============================================================================
# CONFIGURATION OPERATIONS
# =============================================================================

# =============================================================================
# CONFIGURATION INTROSPECTION
# =============================================================================

# List all configuration keys from all scopes
sdk_fac_con_list_keys() {
    set -e
    local scope="$1"  # Optional: if specified, only list keys from this scope
    
    if [ -n "$scope" ]; then
        sdk_fac_con_validate_scope "$scope" || return 1
        local config_file="$(sdk_fac_con_get_config_file "$scope")"
        
        if [ -f "$config_file" ]; then
            echo "Keys in '$scope' scope:"
            sdk_fac_con_yaml_keys "$config_file" | sed 's/^/  /'
        else
            echo "No configuration file found for '$scope' scope"
        fi
    else
        echo "Configuration keys by scope:"
        for scope in $CONFIG_SCOPES; do
            local config_file="$(sdk_fac_con_get_config_file "$scope")"
            
            if [ -f "$config_file" ]; then
                echo ""
                echo "[$scope]"
                sdk_fac_con_yaml_keys "$config_file" | sed 's/^/  /'
            fi
        done
    fi
}

# Show configuration value resolution path
sdk_fac_con_which() {
    set -e
    local key_path="$1"
    
    sdk_fac_con_validate_key_path "$key_path" || return 1
    
    echo "Configuration resolution for '$key_path':"
    
    local found_value=""
    local found_scope=""
    
    for scope in $CONFIG_SCOPES; do
        local config_file="$(sdk_fac_con_get_config_file "$scope")"
        
        if [ -f "$config_file" ]; then
            local value="$(_yq eval ".${key_path}" "$config_file" 2>/dev/null)"
            
            if [ "$value" != "null" ] && [ -n "$value" ]; then
                # Use the value as-is for display
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
sdk_fac_con_print() {
    set -e
    local scope="${1:-all}"  # Default to all scopes
    
    if [ "$scope" = "all" ]; then
        echo "Complete configuration hierarchy:"
        for scope in $CONFIG_SCOPES; do
            local config_file="$(sdk_fac_con_get_config_file "$scope")"
            
            echo ""
            echo "[$scope] - $config_file"
            if [ -f "$config_file" ]; then
                cat "$config_file" | sed 's/^/  /'
            else
                echo "  (no configuration file)"
            fi
        done
    else
        sdk_fac_con_validate_scope "$scope" || return 1
        local config_file="$(sdk_fac_con_get_config_file "$scope")"
        
        echo "Configuration for $scope scope:"
        echo "File: $config_file"
        echo ""
        cat "$config_file"
    fi
}
