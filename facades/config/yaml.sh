#!/bin/bash

# ========================================
# YAML OPERATIONS ENGINE
# ========================================
# Unified YAML operations with yq and fallback support

# =============================================================================
# YAML TOOL DETECTION
# =============================================================================

# Check for yq availability and set operation mode
sdk_fac_con_yaml_init() {
    if command -v yq >/dev/null 2>&1; then
        YAML_USE_YQ="true"
        return 0
    else
        YAML_USE_YQ="false"
        logit -w "yq not found. Using fallback YAML parsing (limited functionality)"
        return 1
    fi
}

# =============================================================================
# YAML OPERATIONS WITH YQ
# =============================================================================

# Get value using yq
sdk_fac_con_yaml_get_yq() {
    local config_file="$1"
    local key_path="$2"
    
    _yq -r ".${key_path}" "$config_file" 2>/dev/null || echo "null"
}

# Set value using yq
sdk_fac_con_yaml_set_yq() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    
    _yq -i ".${key_path} = \"${value}\"" "$config_file"
}

# Delete key using yq
sdk_fac_con_yaml_delete_yq() {
    local config_file="$1"
    local key_path="$2"
    
    _yq -i "del(.${key_path})" "$config_file"
}

# Add to array using yq
sdk_fac_con_yaml_array_add_yq() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    
    # First check if the array exists - if not, just create it with the value
    local array_exists
    array_exists=$(_yq -r ".${key_path} // \"null\"" "$config_file")
    
    if [ "$array_exists" = "null" ]; then
        # Array doesn't exist, create it with the new value
        _yq -i ".${key_path} = [\"${value}\"]" "$config_file"
        return 0
    fi
    
    # Check if value already exists in the array
    # Simplify the approach - use a direct iteration pattern that's more reliable
    local exists=false
    local values
    values=$(_yq -r ".${key_path}[]" "$config_file" 2>/dev/null || echo "")
    
    if echo "$values" | grep -q "^${value}$"; then
        exists=true
    fi
    
    # Only add if it doesn't exist
    if [ "$exists" = "false" ]; then
        _yq -i ".${key_path} += [\"${value}\"]" "$config_file"
    fi
}

# Remove from array using yq
sdk_fac_con_yaml_array_remove_yq() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    
    _yq -i ".${key_path} |= map(select(. != \"${value}\"))" "$config_file"
}

# List all keys using yq
sdk_fac_con_yaml_keys_yq() {
    local config_file="$1"
    
    _yq -r 'paths(scalars) | join(".")' "$config_file" 2>/dev/null || echo ""
}

# =============================================================================
# YAML FALLBACK OPERATIONS
# =============================================================================

# Get value using grep/sed fallback
sdk_fac_con_yaml_get_fallback() {
    local config_file="$1"
    local key_path="$2"
    
    # Only support simple top-level keys in fallback mode
    if echo "$key_path" | grep -q '\.'; then
        echo "null"
        return 1
    fi
    
    if [ -f "$config_file" ]; then
        grep "^${key_path}:" "$config_file" 2>/dev/null | \
        sed "s/^${key_path}: *//" | \
        sed 's/^"//;s/"$//' | \
        head -n1 || echo "null"
    else
        echo "null"
    fi
}

# Set value using grep/sed fallback
sdk_fac_con_yaml_set_fallback() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    
    # Only support simple top-level keys in fallback mode
    if echo "$key_path" | grep -q '\.'; then
        logit -e "Nested keys require yq. Please install yq for full functionality."
        return 1
    fi
    
    # Ensure file exists
    touch "$config_file"
    
    # Remove existing key and add new one
    grep -v "^${key_path}:" "$config_file" > "${config_file}.tmp" 2>/dev/null || touch "${config_file}.tmp"
    echo "${key_path}: ${value}" >> "${config_file}.tmp"
    mv "${config_file}.tmp" "$config_file"
}

# Delete key using grep fallback
sdk_fac_con_yaml_delete_fallback() {
    local config_file="$1"
    local key_path="$2"
    
    if [ -f "$config_file" ]; then
        grep -v "^${key_path}:" "$config_file" > "${config_file}.tmp" 2>/dev/null || touch "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
    fi
}

# List keys using grep fallback
sdk_fac_con_yaml_keys_fallback() {
    local config_file="$1"
    
    if [ -f "$config_file" ]; then
        grep "^[a-zA-Z_][a-zA-Z0-9_]*:" "$config_file" | cut -d: -f1
    fi
}

# =============================================================================
# UNIFIED YAML OPERATIONS INTERFACE
# =============================================================================

# Get value from YAML file
sdk_fac_con_yaml_get() {
    local config_file="$1"
    local key_path="$2"
    sdk_fac_con_yaml_init

    if [ "$YAML_USE_YQ" = "true" ]; then
        sdk_fac_con_yaml_get_yq "$config_file" "$key_path"
    else
        sdk_fac_con_yaml_get_fallback "$config_file" "$key_path"
    fi
}

# Set value in YAML file
sdk_fac_con_yaml_set() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    sdk_fac_con_yaml_init

    if [ "$YAML_USE_YQ" = "true" ]; then
        sdk_fac_con_yaml_set_yq "$config_file" "$key_path" "$value"
    else
        sdk_fac_con_yaml_set_fallback "$config_file" "$key_path" "$value"
    fi
}

# Delete key from YAML file
sdk_fac_con_yaml_delete() {
    local config_file="$1"
    local key_path="$2"
    sdk_fac_con_yaml_init

    if [ "$YAML_USE_YQ" = "true" ]; then
        sdk_fac_con_yaml_delete_yq "$config_file" "$key_path"
    else
        sdk_fac_con_yaml_delete_fallback "$config_file" "$key_path"
    fi
}

# Add to array in YAML file
sdk_fac_con_yaml_array_add() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    sdk_fac_con_yaml_init

    if [ "$YAML_USE_YQ" = "true" ]; then
        sdk_fac_con_yaml_array_add_yq "$config_file" "$key_path" "$value"
    else
        logit -e "Array operations require yq. Please install yq."
        return 1
    fi
}

# Remove from array in YAML file
sdk_fac_con_yaml_array_remove() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    sdk_fac_con_yaml_init

    if [ "$YAML_USE_YQ" = "true" ]; then
        sdk_fac_con_yaml_array_remove_yq "$config_file" "$key_path" "$value"
    else
        logit -e "Array operations require yq. Please install yq."
        return 1
    fi
}

# List all keys in YAML file
sdk_fac_con_yaml_keys() {
    local config_file="$1"
    sdk_fac_con_yaml_init

    if [ "$YAML_USE_YQ" = "true" ]; then
        sdk_fac_con_yaml_keys_yq "$config_file"
    else
        sdk_fac_con_yaml_keys_fallback "$config_file"
    fi
}
