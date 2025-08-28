#!/bin/bash

# Guard to prevent multiple sourcing
if [ "$_INDEXED" = "true" ]; then return 0; fi; _INDEXED="true";

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$KIT_DIR/src/index.sh"

cd "$ROOT_DIR"