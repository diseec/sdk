#!/bin/bash

# ========================================
# CENTRALIZED CONFIGURATION SYSTEM
# ========================================
# Main entry point for the unified configuration management system

# Source all configuration modules
source "$SDK_SRC_DIR/facades/config/vars.sh"
source "$SDK_SRC_DIR/facades/config/caching.sh"
source "$SDK_SRC_DIR/facades/config/core.sh"
source "$SDK_SRC_DIR/facades/config/yaml.sh"
source "$SDK_SRC_DIR/facades/config/hierarchy.sh"
source "$SDK_SRC_DIR/facades/config/options/index.sh"

