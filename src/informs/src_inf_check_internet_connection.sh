#!/bin/bash

src_inf_check_internet_connection() {
    if ! cli_main internet is-online > /dev/null; then
        if ! cli_main internet test > /dev/null; then
            if confirm "Found connection issues, diagnose? ~10 secs"; then
                cli_main internet diagnose
            fi
        fi
    fi
}