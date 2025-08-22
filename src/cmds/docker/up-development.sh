#!/bin/bash

set -e

# Filter services based on workspace configuration
services_filter=$(get_services_filter)

if [ "$IS_IN_CONTAINER" = "true" ]; then
    eval $(grep -m 1 'command:' "$ROOT_DIR/docker-compose.override.yaml" | sed 's/.*command: //')
else
    # Set up a trap to ensure we stop all containers on exit or interrupt
    cleanup() {
        message 33 "CLEANUP" "Stopping all containers..."
        _docker compose down
        exit 0
    }
    # Trap SIGINT (Ctrl+C) and EXIT
    trap cleanup INT EXIT
    
    if [ -n "$services_filter" ]; then
        message 30 "WORKSPACE" "Starting selected services: $services_filter"
        _docker compose up $services_filter
    else
        _docker compose up
    fi
fi
