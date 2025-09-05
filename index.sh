#!/bin/bash

# Guard to prevent multiple sourcing
if [ "$_INDEXED" = "true" ]; then return 0; fi; _INDEXED="true";

if [ -z "${D_SDK_DIR:-}" ]; then
    D_SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Bootstrap the core
source "$D_SDK_DIR/bootstrap/index.sh"

if [ -d "$D_CTX_DIR" ]; then
    cd "$D_CTX_DIR"
fi