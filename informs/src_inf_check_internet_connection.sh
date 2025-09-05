#!/bin/bash

sdk_inf_check_internet_connection() {
    # X "IN sdk_inf_check_internet_connection"
    if ! cli_stub internet is-online > /dev/null; then
        # X "Internet connection appears to be down."
        if ! cli_stub internet test; then
            # X "Internet connectivity test failed."
            if confirm "Found connection issues, diagnose? ~10 secs"; then
                # X "Running diagnostics..."
                cli_stub internet diagnose
            fi
        fi
    fi
}