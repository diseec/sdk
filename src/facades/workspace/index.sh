#!/bin/bash

# workspace/index.sh - Main workspace module that sources all workspace functionality


# This file serves as the main entry point for workspace functionality
# All functions from the individual modules are now available when this file is sourced

# Source all workspace modules
source $KIT_SRC_DIR/facades/workspace/config.sh
source $KIT_SRC_DIR/facades/workspace/modules.sh
source $KIT_SRC_DIR/facades/workspace/yaml-api.sh
source $KIT_SRC_DIR/facades/workspace/fallback.sh
source $KIT_SRC_DIR/facades/workspace/cmds.sh
