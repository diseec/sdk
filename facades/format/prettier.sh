#!/bin/bash

sdk_fac_for_prettier() {

    set -e;

    # if ! grep -q '"prettier"' "$D_CTX_DIR/package.json"; then
    #     stdout -w "Prettier not found. Installing..."
    #     $D_SDK_DIR/cmds/install/prettier.sh
    # fi

    # Use provided arguments or default file patterns
    if [ $# -eq 0 ]; then
        set -- "**/*.{js,jsx,ts,tsx,json,css,scss,md}"
    fi

    stdout -i --ansi="34" --icon="❄︎" --processing "Formatting using Prettier"

    if [ "$D_ENV" = "PIPELINE" ]; then 
        _prettier --check --log-level=warn "$@";
    else
        _prettier --write --log-level=warn "$@";
        stdout -l "Format done."
    fi
}