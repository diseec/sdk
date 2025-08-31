#!/bin/bash

fac_doc_cmd_docker_execute() {

    local IS_SILENT="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        --no-message) IS_SILENT="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    SERVICE_NAME=$1; shift;

    if [ -n "$CI" ]; then
        OPTIONS="-e CI=true";
    else
        OPTIONS="-it";
    fi

    COMMAND_STR="$*"

    if [ "$IS_IN_CONTAINER" = "true" ]; then
        if [ "$IS_SILENT" != "true" ]; then message 40 "▶ $(capitalize $SERVICE_NAME)" "Inside container, Executing '$COMMAND_STR' .."; fi
        "$@"
    else
        if _docker compose ps -q "$SERVICE_NAME" | grep -q .; then
            if [ "$IS_SILENT" != "true" ]; then message 40 "● $(capitalize $SERVICE_NAME)" "Already running, Executing '$COMMAND_STR' .."; fi
            _docker compose exec $OPTIONS "$SERVICE_NAME" "$@"
        else
            if [ "$IS_SILENT" != "true" ]; then message 40 "○ $(capitalize $SERVICE_NAME)" "Not running, Launching an instance, Executing '$COMMAND_STR' .."; fi
            _docker compose run --rm --no-deps $OPTIONS "$SERVICE_NAME" "$@"
        fi
    fi
}