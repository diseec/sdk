#!/bin/bash

# Delegate to the main system-deps script
SRC_KIT cmds/install/system.sh

# First, silently check if dependencies are missing
if ! CLI system dependency-check >/dev/null 2>&1; then
    # Dependencies are missing, show the output this time
    CLI system dependency-check
    # Ask if user wants to install them
    ask_to_run_command "Install missing system dependencies?" CLI system install
fi
