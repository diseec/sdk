#!/bin/bash

# config.sh - YAML config file management API
# Usage: source this file and use config_get, config_set, config_delete, config_create
# Uses $CONFIG_FILE environment variable automatically

get_config_file() {
  CONFIG_FILE="$ORG_DIR/config.yaml"
  if [ ! -f "$CONFIG_FILE" ]; then mkdir -p "$(dirname "$CONFIG_FILE")"; touch "$CONFIG_FILE"; fi
  echo "$CONFIG_FILE"
}

export CONFIG_FILE=$(get_config_file)

# Create config file if not exists
yaml_config_create() {
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "{}" > "$CONFIG_FILE"
    fi
}

# Get value from config (supports nested keys, arrays)
# Usage: config_get <key.path>
config_get() {
    local key_path="$1"
    yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -r ".${key_path}" "$CONFIG_FILE"
    else
        yaml_config_fallback_get "$key_path"
    fi
}

# Set value in config (supports nested keys, arrays)
# Usage: config_set <key.path> <value>
config_set() {
    local key_path="$1"; shift
    local value="$1"
    yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} |= \"${value}\"" "$CONFIG_FILE"
    else
        yaml_config_fallback_set "$key_path" "$value"
    fi
}

# Delete key from config (supports nested keys)
# Usage: config_delete <key.path>
config_delete() {
    local key_path="$1"
    yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i "del(.${key_path})" "$CONFIG_FILE"
    else
        # Simple fallback for top-level keys
        grep -v "^${key_path}:" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || touch "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
}

# Add item to array in config
# Usage: config_array_add <key.path> <value>
config_array_add() {
    local key_path="$1"; shift
    local value="$1"
    yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} += [\"${value}\"]" "$CONFIG_FILE"
    else
        message 31 "ERROR" "Array operations require yq. Please install yq."
        return 1
    fi
}

# Remove item from array in config
# Usage: config_array_remove <key.path> <value>
config_array_remove() {
    local key_path="$1"; shift
    local value="$1"
    yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -i ".${key_path} |= map(select(. != \"${value}\"))" "$CONFIG_FILE"
    else
        message 31 "ERROR" "Array operations require yq. Please install yq."
        return 1
    fi
}

# List all keys in config
# Usage: config_keys
config_keys() {
    yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq -r 'paths(scalars) | join(".")' "$CONFIG_FILE"
    else
        # Simple fallback - just list top-level keys
        grep "^[a-zA-Z_][a-zA-Z0-9_]*:" "$CONFIG_FILE" | cut -d: -f1
    fi
}

# Print whole config
# Usage: config_print
config_print() {
    yaml_config_create
    
    if [ "$yaml_use_yq" = "true" ]; then
        _yq "$CONFIG_FILE"
    else
        cat "$CONFIG_FILE"
    fi
}

# Check for yq dependency and provide fallback
yaml_config_require_yq() {
    if ! command -v _yq >/dev/null 2>&1; then
        message 33 "WARNING" "yq not found. Using fallback methods for YAML parsing."
        return 1
    fi
    return 0
}

# Fallback methods for when yq is not available
yaml_config_fallback_get() {
    local key_path="$1"
    yaml_config_create
    
    # Simple grep-based extraction for basic key-value pairs
    if echo "$key_path" | grep -q '\.'; then
        # Nested keys not supported in fallback
        echo "null"
        return 1
    else
        grep "^${key_path}:" "$CONFIG_FILE" 2>/dev/null | sed "s/^${key_path}: *//" | sed 's/^"//;s/"$//'
    fi
}

yaml_config_fallback_set() {
    local key_path="$1"; shift
    local value="$1"
    yaml_config_create
    
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

# Use yq if available, otherwise fallback
yaml_use_yq=$(yaml_config_require_yq && echo "true" || echo "false")

main() {
    c=$1; shift; case ""$c"" in
        get) config_get "$@" ;;
        set) config_set "$@" ;;
        del|delete) config_delete "$@" ;;
        array_add) config_array_add "$@" ;;
        array_remove) config_array_remove "$@" ;;
        lis|list) config_keys "$@" ;;
        pri|print) config_print "$@" ;;
        *) display_help "" "" \
            "$(color 30 'Config Commands')" "" \
            "    get <key.path>                   " "Get value from configuration" \
            "    set <key.path> <value>           " "Set value in configuration" \
            "    del|delete <key.path>            " "Delete key from configuration" \
            "    array_add <key.path> <val>       " "Add item to array" \
            "    array_remove <key.path> <val>    " "Remove item from array" \
            "    lis|list                         " "List all configuration keys" \
            "    pri|print                        " "Print entire configuration"
        ;;
    esac 
}

main "$@"