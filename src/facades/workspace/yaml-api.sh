#!/bin/bash

# yaml-api.sh - YAML configuration API functions

# Get value from workspace config (supports nested keys)
# Usage: fac_wor_config_get <key.path>
fac_wor_config_get() {
    local key_path="$1"
    local config_file="$(fac_wor_get_config_file)"
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -r ".${key_path}" "$config_file"
    else
        fac_wor_config_fallback_get "$key_path" "$config_file"
    fi
}

# Set value in workspace config (supports nested keys)
# Usage: fac_wor_config_set <key.path> <value>
fac_wor_config_set() {
    local key_path="$1"; shift
    local value="$1"
    local config_file="$(fac_wor_get_config_file)"
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} |= \"${value}\"" "$config_file"
        message 42 "SUCCESS" "Set $key_path = $value in workspace config"
    else
        fac_wor_config_fallback_set "$key_path" "$value" "$config_file"
    fi
}

# Delete key from workspace config (supports nested keys)
# Usage: fac_wor_config_delete <key.path>
fac_wor_config_delete() {
    local key_path="$1"
    local config_file="$(fac_wor_get_config_file)"
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i "del(.${key_path})" "$config_file"
        message 42 "SUCCESS" "Deleted $key_path from workspace config"
    else
        # Simple fallback for top-level keys
        grep -v "^${key_path}:" "$config_file" > "${config_file}.tmp" 2>/dev/null || touch "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
        message 42 "SUCCESS" "Deleted $key_path from workspace config"
    fi
}

# Add item to array in workspace config
# Usage: fac_wor_config_array_add <key.path> <value>
fac_wor_config_array_add() {
    local key_path="$1"; shift
    local value="$1"
    local config_file="$(fac_wor_get_config_file)"
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} += [\"${value}\"]" "$config_file"
        message 42 "SUCCESS" "Added $value to $key_path array in workspace config"
    else
        message 31 "ERROR" "Array operations require yq. Please install yq."
        return 1
    fi
}

# Remove item from array in workspace config
# Usage: fac_wor_config_array_remove <key.path> <value>
fac_wor_config_array_remove() {
    local key_path="$1"; shift
    local value="$1"
    local config_file="$(fac_wor_get_config_file)"
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} |= map(select(. != \"${value}\"))" "$config_file"
        message 42 "SUCCESS" "Removed $value from $key_path array in workspace config"
    else
        message 31 "ERROR" "Array operations require yq. Please install yq."
        return 1
    fi
}

# Print whole workspace config
# Usage: fac_wor_config_print
fac_wor_config_print() {
    local config_file="$(fac_wor_get_config_file)"
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq "$config_file"
    else
        cat "$config_file"
    fi
}
