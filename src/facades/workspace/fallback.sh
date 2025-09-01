#!/bin/bash

# fallback.sh - Fallback methods for when yq is not available

# Fallback methods for when yq is not available
fac_wor_config_fallback_get() {
    local key_path="$1"
    local config_file="$2"
    
    # Simple grep-based extraction for basic key-value pairs
    if echo "$key_path" | grep -q '\.'; then
        # Nested keys not supported in fallback
        echo "null"
        return 1
    else
        grep "^${key_path}:" "$config_file" 2>/dev/null | sed "s/^${key_path}: *//" | sed 's/^"//;s/"$//'
    fi
}

fac_wor_config_fallback_set() {
    local key_path="$1"; shift
    local value="$1"
    local config_file="$2"
    
    # Simple key-value setting for fallback
    if echo "$key_path" | grep -q '\.'; then
        # Nested keys not supported in fallback
        logger -e "Nested keys require yq. Please install yq for full functionality."
        return 1
    fi
    
    # Remove existing key and add new one
    grep -v "^${key_path}:" "$config_file" > "${config_file}.tmp" 2>/dev/null || touch "${config_file}.tmp"
    echo "${key_path}: ${value}" >> "${config_file}.tmp"
    mv "${config_file}.tmp" "$config_file"
    echo "Set $key_path = $value in workspace config"
}
