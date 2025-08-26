#!/bin/bash

set -e; cd $ROOT_DIR;

# if ! grep -q '"prettier"' "$ROOT_DIR/package.json"; then
#     message 43 "!" "Prettier not found. Installing..."
#     SRC cmds/install/prettier.sh
# fi

# Use provided arguments or default file patterns
if [ $# -eq 0 ]; then
    set -- "**/*.{js,jsx,ts,tsx,json,css,scss,md}"
fi

message "Running formatter using Prettier..."

if [ "$CI" = "true" ]; then 
    _prettier --check --log-level=warn "$@";
else
    _prettier --write --log-level=warn "$@";
    echo "Format done."
fi
