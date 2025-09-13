#!/bin/bash

sdk_fac_doc_up_development() {
    set -e

    local IS_RECURSIVE="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        -r|--recursive) IS_RECURSIVE="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    handle_hook before_dev

    # Filter services based on workspace configuration
    services_filter=$(cli_ctx config function sdk_fac_sub_fea_act_get_services_filter)

    if [ "$D_IS_IN_CONTAINER" = "true" ]; then
        if [ -f "$D_CTX_DIR/docker-compose.override.yaml" ]; then
            eval $(grep -m 1 'command:' "$D_CTX_DIR/docker-compose.override.yaml" | sed 's/.*command: //')
        else
            eval $(grep -m 1 'command:' "$D_CTX_DIR/docker-compose.yaml" | sed 's/.*command: //')
        fi
    else
        # Set up a trap to ensure we stop all containers on interrupt
        cleanup() {
            # logit -w "CLEANUP" "Stopping all containers..."
            cli_ctx docker compose _ down
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
            logit "Starting selected services: $services_filter"
            cli_ctx docker compose _ up $services_filter "$@"
        else
            cli_ctx docker compose _ up "$@"
        fi
    fi

    handle_hook after_dev
}