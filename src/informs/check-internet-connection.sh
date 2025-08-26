#!/bin/bash

if ! _CLI_ internet is-online; then
    if ! _CLI_ internet test; then
        ask_to_run_command "Found connection issues, run diagnostics?" _CLI_ internet diagnose
    fi
fi