#!/bin/bash

set -e; cd $ROOT_DIR;

if ! grep -q '"prettier"' "$ROOT_DIR/package.json"; then
    message 43 "!" "Prettier not found. Installing..."
    . $KIT_SRC_DIR/cmds/install/prettier.sh
fi

message 30 "Prettier" "Running formatter..."

if [ "$CI" = "true" ]; then 
    $CLI run yarn prettier --check --log-level=warn "$@";
else
    $CLI run yarn prettier --write --log-level=warn "$@";
fi
