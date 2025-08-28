#!/bin/bash

up_development() {
    SRC_KIT facades/workspace/index.sh

    set -e

    # Filter services based on workspace configuration
    services_filter=$(get_services_filter)

    if [ "$IS_IN_CONTAINER" = "true" ]; then
        if [ -f "$ROOT_DIR/docker-compose.override.yaml" ]; then
            eval $(grep -m 1 'command:' "$ROOT_DIR/docker-compose.override.yaml" | sed 's/.*command: //')
        else
            eval $(grep -m 1 'command:' "$ROOT_DIR/docker-compose.yaml" | sed 's/.*command: //')
        fi
    else
        # Set up a trap to ensure we stop all containers on interrupt
        cleanup() {
            message 33 "CLEANUP" "Stopping all containers..."
            _docker compose down
            exit 0
        }
        
        # Check if running in detached mode
        if [[ "$*" == *"-d"* ]] || [[ "$*" == *"--detach"* ]]; then
            # Only trap SIGINT for detached mode (let script exit normally)
            trap cleanup INT
        else
            # Trap both SIGINT and EXIT for interactive mode
            trap cleanup INT EXIT
        fi
        
        if [ -n "$services_filter" ]; then
            message 30 "WORKSPACE" "Starting selected services: $services_filter"
            _docker compose up $services_filter "$@"
        else
            _docker compose up "$@"
        fi
    fi

}