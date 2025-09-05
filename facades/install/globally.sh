#!/bin/bash

sdk_fac_set_globally() {
    _npm install -g "$(grep '"name"' $D_SDK_DIR/package.json | head -n1 | sed 's/.*: *"\([^"]*\)".*/\1/')@latest"
    logit -o "cli_stub installed globally"
}