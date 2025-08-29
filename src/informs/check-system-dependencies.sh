#!/bin/bash

# Delegate to the main system-deps script
$KIT_SRC_DIR/cmds/install/system.sh

# First, silently check if dependencies are missing
if ! cli_main system dependency-check >/dev/null 2>&1; then
    # Dependencies are missing, show the output this time
    cli_main system dependency-check
    # Ask if user wants to install them
    confirm "Install missing system dependencies?" cli_main system install
fi
