#!/bin/bash
# AI Module - Abstracted AI operations for the kit
# All functions in this module are prefixed with "ai_"

# Load dependencies
. $KIT_SRC_DIR/facades/secret/index.sh

# Load AI module components
. $KIT_SRC_DIR/utils/ai/config.sh
. $KIT_SRC_DIR/utils/ai/utils.sh
. $KIT_SRC_DIR/utils/ai/api.sh
. $KIT_SRC_DIR/utils/ai/generators.sh

# Initialize AI module on load
if ! ai_init; then
    message 33 "WARNING" "AI module loaded but API key not available"
fi
