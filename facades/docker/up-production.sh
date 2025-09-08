#!/bin/bash

sdk_fac_doc_up_production() {
    set -e

    logit "Starting services in production mode .."

    # Filter services based on workspace configuration
    services_filter=$(cli_ctx config function sdk_fac_con_opt_act_get_services_filter)

    # Set up a trap to ensure we stop all containers on exit or interrupt
    cleanup() {
        cli_ctx docker compose _ -f "$D_CTX_DIR/docker-compose.yaml" down
        exit 0
    }
    # Trap SIGINT (Ctrl+C) and EXIT
    trap cleanup INT EXIT

    if [ -n "$services_filter" ]; then
        logit "Starting selected services in production mode: $services_filter"
        cli_ctx docker compose _ -f "$D_CTX_DIR/docker-compose.yaml" up $services_filter "$@"
    else
        cli_ctx docker compose _ -f "$D_CTX_DIR/docker-compose.yaml" up "$@"
    fi

}