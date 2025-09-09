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
# JSON VALIDATION UTILITIES
# =============================================================================

# Check if _jq is available for JSON operations
sdk_fac_con_json_init() {
    if command -v _jq >/dev/null 2>&1; then
        JSON_USE_JQ="true"
        return 0
    else
        JSON_USE_JQ="false"
        logit -w "_jq not found. JSON validation and formatting will be limited."
        return 1
    fi
}

# Validate if a string is valid JSON using _jq
sdk_fac_con_validate_json() {
    local value="$1"
    
    if [ "$JSON_USE_JQ" = "true" ]; then
        echo "$value" | _jq . >/dev/null 2>&1
        return $?
    else
        # Fallback: basic check for JSON-like structure
        local first_char="${value:0:1}"
        [[ "$first_char" == "{" ]] || [[ "$first_char" == "[" ]]
        return $?
    fi
}

# =============================================================================
# YAML OPERATIONS WITH YQ
# =============================================================================

# Get value using yq with proper array handling
sdk_fac_con_yaml_get_yq() {
    local config_file="$1"
    local key_path="$2"
    
    # Try to get array elements first using yq
    local array_elements
    array_elements=$(_yq -r ".${key_path}[]" "$config_file" 2>/dev/null)
    local array_exit_code=$?
    
    # If array query succeeded and returned non-empty results, we have an array
    if [ $array_exit_code -eq 0 ] && [ -n "$array_elements" ]; then
        # Return space-separated array values
        echo "$array_elements" | tr '\n' ' ' | sed 's/ $//'
    else
        # For non-arrays or if array query failed, get the value normally
        local raw_value
        raw_value=$(_yq -r ".${key_path}" "$config_file" 2>/dev/null)
        
        # Check if we got null or empty
        if [ "$raw_value" = "null" ] || [ -z "$raw_value" ]; then
            echo "null"
        else
            echo "$raw_value"
        fi
    fi
}

# Set value using yq with _jq validation for JSON
sdk_fac_con_yaml_set_yq() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    
    # Initialize JSON validation
    sdk_fac_con_json_init
    
    # Use _jq to validate if this is valid JSON
    if sdk_fac_con_validate_json "$value"; then
        # Valid JSON - use _jq to ensure proper formatting and pass to yq
        if [ "$JSON_USE_JQ" = "true" ]; then
            local formatted_json
            formatted_json=$(echo "$value" | _jq -c .)
            _yq -i ".${key_path} = ${formatted_json}" "$config_file"
        else
            # Fallback without _jq formatting
            _yq -i ".${key_path} = ${value}" "$config_file"
        fi
    else
        # Not JSON - treat as regular string and wrap in quotes
        _yq -i ".${key_path} = \"${value}\"" "$config_file"
    fi
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
