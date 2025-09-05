#!/bin/bash

# ========================================
# CENTRALIZED CONFIGURATION CORE
# ========================================
# This module provides a unified configuration system with hierarchy support
# and extensible configuration types

# =============================================================================
# CONFIGURATION PATH RESOLUTION
# =============================================================================

# Get configuration directory for a specific scope and ensure it exists
sdk_fac_con_get_config_dir() {
    local scope="$1"
    local config_dir=""
    
    case "$scope" in
        context) config_dir="$SCOPE_CTX_DIR" ;;
        repository) config_dir="$SCOPE_REPO_DIR" ;;
        user) config_dir="$SCOPE_USER_DIR" ;;
        *) logit -e "Invalid configuration scope: $scope" ; return 1 ;;
    esac
    
    # Create directory if it doesn't exist
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
    fi
    
    echo "$config_dir"
}

# Get configuration file path for a specific scope and ensure it exists
sdk_fac_con_get_config_file() {
    local scope="$1"
    local config_dir="$(sdk_fac_con_get_config_dir "$scope")"
    local config_file=""
    
    case "$scope" in
        context) config_file="$SCOPE_CTX_FILE" ;;
        repository) config_file="$SCOPE_REPO_FILE" ;;
        user) config_file="$SCOPE_USER_FILE" ;;
        *) logit -e "Invalid configuration scope: $scope" ; return 1 ;;
    esac
    
    # Create empty file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
    fi
    
    echo "$config_file"
}

# =============================================================================
# CONFIGURATION VALIDATION
# =============================================================================

# Validate configuration scope
sdk_fac_con_validate_scope() {
    local scope="$1"
    
    if [ -z "$scope" ]; then
        logit -e "Configuration scope cannot be empty"
        return 1
    fi
    
    case "$scope" in
        "user"|"repository"|"context")
            return 0
            ;;
        *)
            logit -e "Invalid configuration scope: $scope. Valid scopes: user, repository, context"
            return 1
            ;;
    esac
}

# Validate configuration key path
sdk_fac_con_validate_key_path() {
    local key_path="$1"
    
    if [ -z "$key_path" ]; then
        logit -e "Configuration key path cannot be empty"
        return 1
    fi
    
    # Check for valid key path format (alphanumeric, dots, underscores, hyphens)
    if ! echo "$key_path" | grep -q '^[a-zA-Z0-9._-]\+$'; then
        logit -e "Invalid key path format: $key_path"
        return 1
    fi
    
    return 0
}
