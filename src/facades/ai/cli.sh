#!/bin/bash
# AI Module - Abstracted AI operations for the kit
# All functions in this module are prefixed with "ai_"

# Initialize AI module on load
if ! fac_ai_init_interactive; then
    logger -w "AI module loaded but API key not available"
fi

c=$1; shift; case "$c" in
    fac_ai_is_available) fac_ai_is_available "$@" ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi 97 'AI Commands')" "" \
            "$(ansi 97 'Usage:    cli ai <command> [options]')" "" "" "" \
            "    fac_ai_is_available   " "Check if AI backend is reachable and key is configured" \
            "    <other commands>      " "AI helper commands implemented in this module" \
            "" "" "$(ansi 33 'Setup Required')" "" \
            "    D secret add           " "Add OPENAI_API_KEY to secrets for AI features" \
            "    Check: secrets ksh     " "Show current secrets and verify key presence" \
            "$@"
    ;;
esac 
