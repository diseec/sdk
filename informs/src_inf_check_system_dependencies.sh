#!/bin/bash

sdk_inf_check_system_dependencies() {
    # First, silently check if dependencies are missing
    if ! cli_stub install system dependency-check >/dev/null 2>&1; then
        # Dependencies are missing, show the output this time
        cli_stub install system dependency-check
        # Ask if user wants to install them
        confirm "Install missing system dependencies?" cli_stub install system install
    fi
}
