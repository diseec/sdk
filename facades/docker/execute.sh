#!/bin/bash

sdk_fac_doc_cmd_docker_execute() {

    local IS_QUIET="false"
    ARGS=""; for arg in "$@"; do case "$arg" in
        --quiet)
            IS_QUIET="true"; RUN_OPTIONS="--quiet"
        ;;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    SERVICE_NAME=$1; shift;

    if [ -n "$CI" ]; then
        OPTIONS="-e CI=true";
    else
        OPTIONS="-it";
    fi

    COMMAND_STR="$*"

    if [ "$D_IS_IN_CONTAINER" = "true" ]; then
        if [ "$IS_QUIET" != "true" ]; then stdout --ansi="36" --icon="$(capitalize $SERVICE_NAME) ▶" "Inside container, Executing '$COMMAND_STR' .."; fi
        "$@"
    else
        if cli_ctx docker compose _ ps -q "$SERVICE_NAME" | grep -q .; then
            if [ "$IS_QUIET" != "true" ]; then stdout --ansi="96" --icon="$(capitalize $SERVICE_NAME) ●" "Already running, Executing '$COMMAND_STR' .."; fi
            cli_ctx docker compose _ exec $OPTIONS "$SERVICE_NAME" "$@"
        else
            if [ "$IS_QUIET" != "true" ]; then stdout --ansi="90" --icon="$(capitalize $SERVICE_NAME) ○" "Not running, Launching an instance, Executing '$COMMAND_STR' .."; fi
            cli_ctx docker compose _ run --rm --no-deps $OPTIONS $RUN_OPTIONS "$SERVICE_NAME" "$@"
        fi
    fi
}