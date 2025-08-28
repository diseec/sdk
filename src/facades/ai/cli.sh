#!/bin/bash
# AI Module - Abstracted AI operations for the kit
# All functions in this module are prefixed with "ai_"

# Initialize AI module on load
if ! fac_ai_init; then
    message 33 "WARNING" "AI module loaded but API key not available"
fi

c=$1; shift; case "$c" in
    fac_ai_is_available) fac_ai_is_available "$@" ;;
esac 
