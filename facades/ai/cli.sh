#!/bin/bash

source_once "$D_SDK_DIR/facades/ai/index.sh"

# AI Module - Abstracted AI operations for the sdk
# All functions in this module are prefixed with "ai_"

# Initialize AI module on load
if ! src_fac_ai_init_interactive; then
    logit -w "AI module loaded but API key not available"
fi

c=$1; shift; case "$c" in
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi 97 'AI Commands')" "" \
            "$(ansi 97 'Usage:    cli ai <command> [options]')" "" "" "" \
            "    <other commands>      " "AI helper commands implemented in this module" \
            "" "" "$(ansi 33 'Setup Required')" "" \
            "    $D_CLI_GLOBAL_NAME secret add           " "Add OPENAI_API_KEY to secrets for AI features" \
            "    Check: secrets ksh     " "Show current secrets and verify key presence" \
            "$@"
    ;;
    fun|function) "$@" ;;
esac 
