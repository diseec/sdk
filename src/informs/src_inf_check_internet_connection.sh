#!/bin/bash

src_inf_check_internet_connection() {
    # bug "IN src_inf_check_internet_connection"
    if ! cli_main internet is-online > /dev/null; then
        # bug "Internet connection appears to be down."
        if ! cli_main internet test; then
            # bug "Internet connectivity test failed."
            if confirm "Found connection issues, diagnose? ~10 secs"; then
                # bug "Running diagnostics..."
                cli_main internet diagnose
            fi
        fi
    fi
}