#!/bin/bash
# AI Module - Abstracted AI operations for the kit
# All functions in this module are prefixed with "ai_"

main() {

    # Load dependencies
    SRC_KIT facades/secret/index.sh

    # Load AI module components
    SRC_KIT facades/ai/config.sh
    SRC_KIT facades/ai/utils.sh
    SRC_KIT facades/ai/api.sh
    SRC_KIT facades/ai/generators.sh

    # Initialize AI module on load
    if ! ai_init; then
        message 33 "WARNING" "AI module loaded but API key not available"
    fi

    c=$1; shift; case "$c" in
        # t) echo "$@" ;;
        ai_is_available) ai_is_available "$@" ;;
    esac 
}
