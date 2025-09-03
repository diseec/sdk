#!/bin/bash

source "$KIT_DIR/src/core/envs/index.sh" # setup environment

source "$KIT_SRC_DIR/core/debug.sh"
src_cor_debug_init

source "$KIT_SRC_DIR/core/utils.sh"
source "$KIT_SRC_DIR/core/outputs.sh"
source "$KIT_SRC_DIR/core/wrappers.sh"
source "$KIT_SRC_DIR/core/hooks.sh"