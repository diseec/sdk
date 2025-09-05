#!/bin/bash

# workspace/index.sh - Main workspace module that sources all workspace functionality

# Source all workspace submodules
source "$D_SDK_DIR/facades/config/options/active_modules/config.sh"
source "$D_SDK_DIR/facades/config/options/active_modules/submodules.sh"
source "$D_SDK_DIR/facades/config/options/active_modules/fallback.sh"
source "$D_SDK_DIR/facades/config/options/active_modules/cmds.sh"
source "$D_SDK_DIR/facades/config/options/active_modules/caching.sh"
