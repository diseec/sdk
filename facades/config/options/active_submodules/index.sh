#!/bin/bash

# workspace/index.sh - Main workspace module that sources all workspace functionality

# Source all workspace submodules
source "$D_SDK_DIR/facades/config/options/active_submodules/config.sh"
source "$D_SDK_DIR/facades/config/options/active_submodules/helpers.sh"
source "$D_SDK_DIR/facades/config/options/active_submodules/cmds.sh"
