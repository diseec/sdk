#!/bin/bash

sdk_fac_ins_globally() {
    _npm install -g "$(grep '"name"' $D_SDK_DIR/package.json | head -n1 | sed 's/.*: *"\([^"]*\)".*/\1/')@latest"
    stdout -o "cli_ctx installed globally"
}