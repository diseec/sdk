#!/bin/bash

# =============================================================================
# CONFIGURATION CONSTANTS AND TYPES
# =============================================================================

# Configuration file names and structure
readonly CONFIG_PROJECT_FILE="config.yaml"
readonly CONFIG_WORKSPACE_FILE="config.yaml"
# readonly CONFIG_USER_FILE="config.yaml"
readonly CONFIG_GLOBAL_FILE="config.yaml"

# Configuration scopes in order of precedence (highest to lowest)
readonly CONFIG_SCOPES="project workspace global"

# ========================================
# CENTRALIZED CONFIGURATION SYSTEM
# ========================================
# Main entry point for the unified configuration management system

# Source all configuration modules
source "$KIT_SRC_DIR/facades/config/core.sh"
source "$KIT_SRC_DIR/facades/config/yaml.sh"
source "$KIT_SRC_DIR/facades/config/hierarchy.sh"

# # Initialize YAML operations on load
fac_con_yaml_init