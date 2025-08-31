#!/bin/bash

fac_doc_up_production() {
    set -e

    message "Starting services in production mode .."

    # Filter services based on workspace configuration
    services_filter=$(fac_wor_get_services_filter)

    # Set up a trap to ensure we stop all containers on exit or interrupt
    cleanup() {
        _docker compose -f "$ROOT_DIR/docker-compose.yaml" down
        exit 0
    }
    # Trap SIGINT (Ctrl+C) and EXIT
    trap cleanup INT EXIT

    if [ -n "$services_filter" ]; then
        message 34 "WORKSPACE" "Starting selected services in production mode: $services_filter"
        _docker compose -f "$ROOT_DIR/docker-compose.yaml" up $services_filter "$@"
    else
        _docker compose -f "$ROOT_DIR/docker-compose.yaml" up "$@"
    fi

}