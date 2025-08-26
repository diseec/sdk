#!/bin/bash
# AI Module - Abstracted AI operations for the kit
# All functions in this module are prefixed with "ai_"

main() {

    # Load dependencies
    SRC facades/secret/index.sh

    # Load AI module components
    SRC facades/ai/config.sh
    SRC facades/ai/utils.sh
    SRC facades/ai/api.sh
    SRC facades/ai/generators.sh

    # Initialize AI module on load
    if ! ai_init; then
        message 33 "WARNING" "AI module loaded but API key not available"
    fi

    c=$1; shift; case "$c" in
        # t) echo "$@" ;;
        ai_is_available) ai_is_available "$@" ;;
    esac 
}
