#!/bin/bash

sdk_fac_doc_up_development() {
    handle_hook before_dev
    
    processing_start "BRAILLE_MIXED"

    # # Filter services based on workspace configuration
    services_filter=$(cli_ctx --quiet submodule function sdk_fac_sub_fea_act_get_services_filter)

    if [ "$D_IS_IN_CONTAINER" = "true" ]; then
        if [ -f "$D_CTX_DIR/docker-compose.override.yaml" ]; then
            eval $(grep -m 1 'command:' "$D_CTX_DIR/docker-compose.override.yaml" | sed 's/.*command: //')
        else
            eval $(grep -m 1 'command:' "$D_CTX_DIR/docker-compose.yaml" | sed 's/.*command: //')
        fi
    else
        # Set up a trap to ensure we stop all containers on interrupt
        cleanup() {
            # remove any traps while cleaning to avoid recursion
            trap - INT TERM EXIT

            # Friendly log for users / debug
            stdout -l --processing "Stopping all containers and cleaning up"

            # Try a hard stop first (best-effort), then bring the compose project down
            # Remove orphans to avoid leftover dependencies
            cli_ctx docker compose _ kill 2>/dev/null || true
            cli_ctx docker compose _ down --remove-orphans 2>/dev/null || true

            stdout -l "CLEANUP" "Done."
            return 0
        }
        
        # Determine whether user requested detached mode
        if [[ "$*" == *"-d"* ]] || [[ "$*" == *"--detach"* ]]; then
            is_detached=true
        else
            is_detached=false
        fi
        
        processing_stop

        if [ -n "$services_filter" ]; then
            stdout -l "Starting selected services: $services_filter"
            if [ "$is_detached" = false ]; then
                # interactive (foreground) mode: trap interrupts while compose is running,
                # and run cleanup immediately after compose exits.
                trap cleanup INT TERM
                cli_ctx docker compose _ up $services_filter "$@"
                trap - INT TERM
                cleanup
            else
                # detached: run and return immediately (no automatic cleanup)
                cli_ctx docker compose _ up $services_filter "$@"
            fi
        else
            if [ "$is_detached" = false ]; then
                trap cleanup INT TERM
                cli_ctx docker compose _ up "$@"
                trap - INT TERM
                cleanup
            else
                cli_ctx docker compose _ up "$@"
            fi
        fi
    fi
    
    processing_stop

    handle_hook after_dev
}