#!/bin/bash

source "$D_SDK_DIR/bootstrap/environment/index.sh"

sdk_boo_env_setup_environment

# Load app wide common utilities
source "$D_SDK_DIR/shared/index.sh"

# Load bootstrap modules
source "$D_SDK_DIR/bootstrap/debug.sh"
source "$D_SDK_DIR/bootstrap/hooks.sh"

sdk_boo_debug_init
