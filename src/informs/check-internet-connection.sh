#!/bin/bash

if ! cli_main internet is-online; then
    if ! cli_main internet test; then
        confirm "Found connection issues, run diagnostics?" cli_main internet diagnose
    fi
fi