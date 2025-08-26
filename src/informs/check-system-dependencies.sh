#!/bin/bash

# Delegate to the main system-deps script
SRC cmds/install/system.sh

# First, silently check if dependencies are missing
if ! _CLI_ system dependency-check >/dev/null 2>&1; then
    # Dependencies are missing, show the output this time
    _CLI_ system dependency-check
    # Ask if user wants to install them
    ask_to_run_command "Install missing system dependencies?" _CLI_ system install
fi
