#!/bin/bash

# Logging and output functions for internet connectivity checker

log_status() {
    local status=$1
    local test_name=$2
    local details=$3
    local timing=$4

    # In is-online mode, be completely silent - no output at all
    if [ "$MODE" = "is-online" ]; then
        return
    fi
    
    # In silent mode, only show failures and warnings
    if [ "$SILENT_MODE" = "true" ] && [ "$status" = "SUCCESS" ]; then
        return
    fi
    
    # Format output with timestamp and detailed info
    local timestamp=$(date '+%H:%M:%S')
        if [ "$status" = "SUCCESS" ]; then
        if [ "$MODE" = "diagnose" ] || [ "$MODE" = "test" ]; then
            printf "[%s]${NC}[PASS]${NC} %s" "$timestamp" "$test_name"
            [ -n "$details" ] && printf " - %s" "$details"
            [ -n "$timing" ] && printf " (took %s)" "$timing"
            printf "\n"
        fi
    elif [ "$status" = "WARNING" ]; then
        printf "[%s]${YELLOW}[WARN]${NC} %s" "$timestamp" "$test_name"
        [ -n "$details" ] && printf " - %s" "$details"
        [ -n "$timing" ] && printf " (took %s)" "$timing"
        printf "\n"
    else
        printf "[%s]${RED}[FAIL]${NC} %s" "$timestamp" "$test_name"
        [ -n "$details" ] && printf " - %s" "$details"
        [ -n "$timing" ] && printf " (took %s)" "$timing"
        printf "\n"
    fi
}