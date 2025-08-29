#!/bin/bash

env_uti_validate_environment() {
    local errors=0
    
    # Check required directories
    if [ ! -d "$ROOT_DIR" ]; then
        echo "Error: ROOT_DIR not found: $ROOT_DIR" >&2
        errors=$((errors + 1))
    fi
    
    if [ ! -d "$KIT_DIR" ]; then
        echo "Error: KIT_DIR not found: $KIT_DIR" >&2
        errors=$((errors + 1))
    fi
    
    # Check required files
    if [ ! -f "$CLI_MAIN" ]; then
        echo "Warning: CLI_MAIN not found: $CLI_MAIN" >&2
    fi
    
    return $errors
}
