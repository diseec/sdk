#!/bin/bash

_npm install -g "$(grep '"name"' $KIT_DIR/package.json | head -n1 | sed 's/.*: *"\([^"]*\)".*/\1/')@latest"
message 42 "OKEY" "CLI installed globally"
