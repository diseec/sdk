#!/bin/bash

source "$D_SDK_DIR/facades/ai/config.sh"
source "$D_SDK_DIR/facades/ai/utils.sh"
source "$D_SDK_DIR/facades/ai/api.sh"
source "$D_SDK_DIR/facades/ai/generators.sh"

# Load command implementations
source "$D_SDK_DIR/facades/ai/cmds/init.sh"
source "$D_SDK_DIR/facades/ai/cmds/availability.sh"
source "$D_SDK_DIR/facades/ai/cmds/generate.sh"
source "$D_SDK_DIR/facades/ai/cmds/prompts.sh"
