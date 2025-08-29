#!/bin/bash

# First, silently check if dependencies are missing
if ! cli_main setup system dependency-check >/dev/null 2>&1; then
    # Dependencies are missing, show the output this time
    cli_main setup system dependency-check
    # Ask if user wants to install them
    confirm "Install missing system dependencies?" cli_main setup system install
fi
