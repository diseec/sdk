#!/bin/bash

src_fac_set_globally() {
    _npm install -g "$(grep '"name"' $SDK_DIR/package.json | head -n1 | sed 's/.*: *"\([^"]*\)".*/\1/')@latest"
    logit -o "cli_main installed globally"
}