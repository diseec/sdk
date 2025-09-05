#!/bin/bash

# Guard to prevent multiple sourcing
if [ "$_INDEXED" = "true" ]; then return 0; fi; _INDEXED="true";

if [ -z "${SDK_DIR:-}" ]; then
    SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source the main index file
source "$SDK_DIR/src/index.sh"

if [ -d "$WORK_DIR" ]; then
    cd "$WORK_DIR"
fi
