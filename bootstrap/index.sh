#!/bin/bash

source "$D_SDK_DIR/bootstrap/environment/index.sh"

src_cor_env_setup_environment

source "$D_SDK_DIR/shared/index.sh" # Load cross app common utilities

source "$D_SDK_DIR/bootstrap/debug.sh"
source "$D_SDK_DIR/bootstrap/hooks.sh"

src_cor_debug_init
