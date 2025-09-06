#!/bin/bash

source "$D_SDK_DIR/shared/utils.sh"
source "$D_SDK_DIR/shared/outputs.sh"
source "$D_SDK_DIR/shared/wrappers.sh"

# Source tester framework if available
if [ -f "$D_SDK_DIR/lib/tester/index.sh" ]; then
    source "$D_SDK_DIR/lib/tester/index.sh"
fi
