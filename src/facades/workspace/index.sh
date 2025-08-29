#!/bin/bash

# workspace/index.sh - Main workspace module that sources all workspace functionality

# Source all workspace submodules
source $KIT_SRC_DIR/facades/workspace/config.sh
source $KIT_SRC_DIR/facades/workspace/submodules.sh
source $KIT_SRC_DIR/facades/workspace/fallback.sh
source $KIT_SRC_DIR/facades/workspace/cmds.sh
