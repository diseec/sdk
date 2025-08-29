#!/bin/bash

# ========================================
# CENTRALIZED CONFIGURATION CORE
# ========================================
# This module provides a unified configuration system with hierarchy support
# and extensible configuration types

# =============================================================================
# CONFIGURATION PATH RESOLUTION
# =============================================================================

# Get configuration directory for a specific scope
fac_con_get_config_dir() {
    local scope="$1"
    
    case "$scope" in
        global) echo "$ORG_DIR" ;;
        # user) echo "$ORG_DIR/users/$(whoami)" ;;
        workspace) echo "$ORG_DIR/workspaces/$REPO_NAME" ;;
        project) echo "$ROOT_DIR/.$KIT_NAME" ;;
        *) message 41 "!" "Invalid configuration scope: $scope" ; return 1 ;;
    esac
}

# Get configuration file path for a specific scope
fac_con_get_config_file() {
    local scope="$1"
    local config_dir="$(fac_con_get_config_dir "$scope")"
    
    case "$scope" in
        global) echo "$config_dir/$CONFIG_GLOBAL_FILE" ;;
        # user) echo "$config_dir/$CONFIG_USER_FILE" ;;
        workspace) echo "$config_dir/$CONFIG_WORKSPACE_FILE" ;;
        project) echo "$config_dir/$CONFIG_PROJECT_FILE" ;;
        *) message 41 "!" "Invalid configuration scope: $scope" ; return 1 ;;
    esac
}

# Ensure configuration file exists for a scope
fac_con_ensure_config_file() {
    local scope="$1"
    local config_file="$(fac_con_get_config_file "$scope")"
    local config_dir="$(dirname "$config_file")"
    
    # Create directory if it doesn't exist
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
    fi
    
    # Create file with default content if it doesn't exist
    if [ ! -f "$config_file" ]; then
        case "$scope" in
            global)
                cat > "$config_file" << 'EOF'
# Global configuration for the entire organization
EOF
                ;;
            workspace)
                cat > "$config_file" << 'EOF'
# Workspace-specific configuration
submodules: []
secrets:
  key: <SECRET_KEY>
EOF
                ;;
            project)
                cat > "$config_file" << 'EOF'
# Project-specific configuration
EOF
                ;;
        esac
    fi
    
    echo "$config_file"
}

# =============================================================================
# CONFIGURATION VALIDATION
# =============================================================================

# Validate configuration scope
fac_con_validate_scope() {
    local scope="$1"
    
    if [ -z "$scope" ]; then
        message 41 "!" "Configuration scope cannot be empty"
        return 1
    fi
    
    case "$scope" in
        "global"|"workspace"|"project")
            return 0
            ;;
        *)
            message 41 "!" "Invalid configuration scope: $scope. Valid scopes: global, user, workspace, project"
            return 1
            ;;
    esac
}

# Validate configuration key path
fac_con_validate_key_path() {
    local key_path="$1"
    
    if [ -z "$key_path" ]; then
        message 41 "!" "Configuration key path cannot be empty"
        return 1
    fi
    
    # Check for valid key path format (alphanumeric, dots, underscores, hyphens)
    if ! echo "$key_path" | grep -q '^[a-zA-Z0-9._-]\+$'; then
        message 41 "!" "Invalid key path format: $key_path"
        return 1
    fi
    
    return 0
}
