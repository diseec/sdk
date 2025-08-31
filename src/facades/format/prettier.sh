#!/bin/bash

fac_for_prettier() {

    set -e;

    # if ! grep -q '"prettier"' "$ROOT_DIR/package.json"; then
    #     message 33 "!" "Prettier not found. Installing..."
    #     $KIT_SRC_DIR/cmds/install/prettier.sh
    # fi

    # Use provided arguments or default file patterns
    if [ $# -eq 0 ]; then
        set -- "**/*.{js,jsx,ts,tsx,json,css,scss,md}"
    fi

    message 34 "❄︎" "Running formatter using Prettier..."

    if [ "$CI" = "true" ]; then 
        _prettier --check --log-level=warn "$@";
    else
        _prettier --write --log-level=warn "$@";
        echo "Format done."
    fi

}