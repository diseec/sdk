#!/bin/bash

# Guard to prevent multiple sourcing
if [ "$_INDEXED" = "true" ]; then return 0; fi; _INDEXED="true";

SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the main index file
source "$SDK_DIR/src/index.sh"

cd "$WORK_DIR"
