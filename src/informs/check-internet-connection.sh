#!/bin/bash

if ! "$CLI" internet is-online; then
    if ! $CLI internet test; then
        ask_to_run_command "Found connection issues, run diagnostics?" $CLI internet diagnose
    fi
fi