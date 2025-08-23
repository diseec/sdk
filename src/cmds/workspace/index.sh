#!/bin/bash

# workspace/index.sh - Main workspace module that sources all workspace functionality

# Source config facade to get YAML utilities
. $KIT_SRC_DIR/facades/config.sh

# Source all workspace modules
. $KIT_SRC_DIR/cmds/workspace/config.sh
. $KIT_SRC_DIR/cmds/workspace/modules.sh
. $KIT_SRC_DIR/cmds/workspace/yaml-api.sh
. $KIT_SRC_DIR/cmds/workspace/fallback.sh
. $KIT_SRC_DIR/cmds/workspace/commands.sh

# This file serves as the main entry point for workspace functionality
# All functions from the individual modules are now available when this file is sourced
