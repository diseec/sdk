#!/bin/bash

sdk_fac_inf_check_internet_connection() {
    processing_start "BRAILLE_MIXED"
    # X "IN sdk_fac_inf_check_internet_connection"
    if ! cli_ctx internet is-online > /dev/null; then
        processing_stop
        # X "Internet connection appears to be down."
        if ! cli_ctx internet test; then
            # X "Internet connectivity test failed."
            if confirm "Found connection issues, diagnose? ~10 secs"; then
                # X "Running diagnostics..."
                cli_ctx internet diagnose
            fi
        fi
    fi
    processing_stop
}