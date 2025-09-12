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

# Get value using yq with proper array handling - pure YAML output
sdk_fac_con_yaml_get_yq() {
    local config_file="$1"
    local key_path="$2"
    
    # Check if the key exists first
    if ! _yq eval "has(\"${key_path//./\".\"}\")" "$config_file" >/dev/null 2>&1; then
        echo "null"
        return 1
    fi
    
    # Get the value and return raw YAML output
    local value
    value=$(_yq eval ".${key_path}" "$config_file" 2>/dev/null)
    
    if [ "$value" = "null" ] || [ -z "$value" ]; then
        echo "null"
        return 1
    fi
    
    echo "$value"
}

# Set value using yq - pure YAML operations
sdk_fac_con_yaml_set_yq() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    
    # Handle YAML array in standard format [item1,item2,item3]
    if [[ "$value" == \[* ]] && [[ "$value" == *\] ]]; then
        # Extract items and create properly quoted array for yq
        # Remove brackets
        local items=${value:1:${#value}-2}
        
        # Create a properly quoted array for yq
        local quoted_array="["
        IFS=',' read -ra array_items <<< "$items"
        local first=true
        for item in "${array_items[@]}"; do
            item=$(echo "$item" | xargs)  # trim whitespace
            if [ "$first" = true ]; then
                quoted_array="${quoted_array}\"${item}\""
                first=false
            else
                quoted_array="${quoted_array}, \"${item}\""
            fi
        done
        quoted_array="${quoted_array}]"
        
        # Now use the properly quoted array with yq
        _yq eval -i ".${key_path} = ${quoted_array}" "$config_file"
    else
        # Regular scalar value or object
        _yq eval -i ".${key_path} = \"${value}\"" "$config_file"
    fi
}

# Delete key using yq
sdk_fac_con_yaml_delete_yq() {
    local config_file="$1"
    local key_path="$2"
    
    _yq eval -i "del(.${key_path})" "$config_file"
}

# List all keys using yq
sdk_fac_con_yaml_keys_yq() {
    local config_file="$1"
    
    _yq eval 'paths(scalars) | join(".")' "$config_file" 2>/dev/null || echo ""
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

# Remove from array in YAML file
sdk_fac_con_yaml_array_remove() {
    local config_file="$1"
    local key_path="$2"
    local value="$3"
    sdk_fac_con_yaml_init

    if [ "$YAML_USE_YQ" = "true" ]; then
        # First check if the target is a scalar value that matches what we want to remove
        local current_value
        current_value=$(_yq eval ".${key_path}" "$config_file" 2>/dev/null)
        
        if [ "$current_value" = "$value" ]; then
            # It's a scalar value that matches - replace with empty array
            _yq eval -i ".${key_path} = []" "$config_file"
        else
            # It's an array - use the map/select approach
            _yq eval -i ".${key_path} |= map(select(. != \"${value}\"))" "$config_file"
        fi
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
