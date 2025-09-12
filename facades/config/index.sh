#!/bin/bash

# ========================================
# CENTRALIZED CONFIGURATION SYSTEM
# ========================================
# Main entry point for the unified configuration management system

# Source all configuration modules
source "$D_SDK_DIR/facades/config/vars.sh"
source "$D_SDK_DIR/facades/config/caching.sh"
source "$D_SDK_DIR/facades/config/core.sh"
source "$D_SDK_DIR/facades/config/yaml.sh"
source "$D_SDK_DIR/facades/config/cmds.sh"
source "$D_SDK_DIR/facades/config/settings/index.sh"

