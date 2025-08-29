#!/bin/bash

# config.sh - YAML config file management API
# Usage: source this file and use fac_con_config_get, fac_con_config_set, fac_con_config_delete, config_create
# Uses $CONFIG_FILE environment variable automatically

fac_con_get_config_file() {
  CONFIG_FILE="$ORG_DIR/config.yaml"
  if [ ! -f "$CONFIG_FILE" ]; then mkdir -p "$(dirname "$CONFIG_FILE")"; touch "$CONFIG_FILE"; fi
  echo "$CONFIG_FILE"
}

# Create config file if not exists
fac_con_yaml_config_create() {
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "{}" > "$CONFIG_FILE"
    fi
}

# Get value from config (supports nested keys, arrays)
# Usage: fac_con_config_get <key.path>
fac_con_config_get() {
    local key_path="$1"
    fac_con_yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -r ".${key_path}" "$CONFIG_FILE"
    else
        fac_con_yaml_config_fallback_get "$key_path"
    fi
}

# Set value in config (supports nested keys, arrays)
# Usage: fac_con_config_set <key.path> <value>
fac_con_config_set() {
    local key_path="$1"; shift
    local value="$1"
    fac_con_yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} |= \"${value}\"" "$CONFIG_FILE"
    else
        fac_con_yaml_config_fallback_set "$key_path" "$value"
    fi
}

# Delete key from config (supports nested keys)
# Usage: fac_con_config_delete <key.path>
fac_con_config_delete() {
    local key_path="$1"
    fac_con_yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i "del(.${key_path})" "$CONFIG_FILE"
    else
        # Simple fallback for top-level keys
        grep -v "^${key_path}:" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || touch "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
}

# Add item to array in config
# Usage: fac_con_config_array_add <key.path> <value>
fac_con_config_array_add() {
    local key_path="$1"; shift
    local value="$1"
    fac_con_yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} += [\"${value}\"]" "$CONFIG_FILE"
    else
        message 31 "ERROR" "Array operations require yq. Please install yq."
        return 1
    fi
}

# Remove item from array in config
# Usage: fac_con_config_array_remove <key.path> <value>
fac_con_config_array_remove() {
    local key_path="$1"; shift
    local value="$1"
    fac_con_yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} |= map(select(. != \"${value}\"))" "$CONFIG_FILE"
    else
        message 31 "ERROR" "Array operations require yq. Please install yq."
        return 1
    fi
}

# List all keys in config
# Usage: fac_con_config_keys
fac_con_config_keys() {
    fac_con_yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -r 'paths(scalars) | join(".")' "$CONFIG_FILE"
    else
        # Simple fallback - just list top-level keys
        grep "^[a-zA-Z_][a-zA-Z0-9_]*:" "$CONFIG_FILE" | cut -d: -f1
    fi
}

# Print whole config
# Usage: fac_con_config_print
fac_con_config_print() {
    fac_con_yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq "$CONFIG_FILE"
    else
        cat "$CONFIG_FILE"
    fi
}

# Check for yq dependency and provide fallback
fac_con_yaml_config_require_yq() {
    if ! command -v _yq >/dev/null 2>&1; then
        message 33 "WARNING" "yq not found. Using fallback methods for YAML parsing."
        return 1
    fi
    return 0
}

# Fallback methods for when yq is not available
fac_con_yaml_config_fallback_get() {
    local key_path="$1"
    fac_con_yaml_config_create
    
    # Simple grep-based extraction for basic key-value pairs
    if echo "$key_path" | grep -q '\.'; then
        # Nested keys not supported in fallback
        echo "null"
        return 1
    else
        grep "^${key_path}:" "$CONFIG_FILE" 2>/dev/null | sed "s/^${key_path}: *//" | sed 's/^"//;s/"$//'
    fi
}

fac_con_yaml_config_fallback_set() {
    local key_path="$1"; shift
    local value="$1"
    fac_con_yaml_config_create
    
    # Simple key-value setting for fallback
    if echo "$key_path" | grep -q '\.'; then
        # Nested keys not supported in fallback
        message 31 "ERROR" "Nested keys require yq. Please install yq for full functionality."
        return 1
    fi
    
    # Remove existing key and add new one
    grep -v "^${key_path}:" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || touch "${CONFIG_FILE}.tmp"
    echo "${key_path}: ${value}" >> "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}
