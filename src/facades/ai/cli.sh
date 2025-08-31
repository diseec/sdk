#!/bin/bash
# AI Module - Abstracted AI operations for the kit
# All functions in this module are prefixed with "ai_"

# Initialize AI module on load
if ! fac_ai_init; then
    message -w "AI module loaded but API key not available"
fi

c=$1; shift; case "$c" in
    fac_ai_is_available) fac_ai_is_available "$@" ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(color 37 'AI Commands')" "" \
            "$(color 37 'Usage:    cli ai <command> [options]\n')" "" \
            "    fac_ai_is_available   " "Check if AI backend is reachable and key is configured" \
            "    <other commands>      " "AI helper commands implemented in this module" \
            "" "" "$(color 33 'Setup Required')" "" \
            "    D secret add           " "Add OPENAI_API_KEY to secrets for AI features" \
            "    Check: secrets ksh     " "Show current secrets and verify key presence" \
            "$@"
    ;;
esac 
