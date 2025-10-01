#!/bin/bash

sdk_fac_doc_cmd_docker_execute() {
    local RUN_OPTIONS="--no-deps"
    local IS_QUIET="false"
    local DEFAULT_OPTIONS=""

    local ARGS=""; for arg in "$@"; do case "$arg" in
        --quiet)
            IS_QUIET="true"; RUN_OPTIONS="$RUN_OPTIONS --quiet"
        ;;
        --with-deps)
            RUN_OPTIONS=$(echo $RUN_OPTIONS | sed 's/--no-deps//g')
        ;;
        --entrypoint=*) RUN_OPTIONS="$RUN_OPTIONS $arg" ;;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    SERVICE_NAME=$1; shift;

    # # always use host user:group when running commands inside containers
    # HOST_UID=${HOST_UID:-$(id -u)}
    # HOST_GID=${HOST_GID:-$(id -g)}
    # USER_FLAG="--user ${HOST_UID}:${HOST_GID}"

    if [ -n "$CI" ]; then
        DEFAULT_OPTIONS="-e CI=true";
    else
        DEFAULT_OPTIONS="-it";
    fi

    local COMMAND_STR="$*"

    if [ "$D_IS_IN_CONTAINER" = "true" ]; then
        if [ "$IS_QUIET" != "true" ]; then stdout --processing --ansi="36" --icon="$(capitalize $SERVICE_NAME) ▶" "Inside container, Executing '$COMMAND_STR'"; fi
        "$@"
    else
        if cli_ctx docker compose _ ps -q "$SERVICE_NAME" | grep -q .; then
            if [ "$IS_QUIET" != "true" ]; then stdout --processing --ansi="96" --icon="$(capitalize $SERVICE_NAME) ●" "Already running, Executing '$COMMAND_STR'"; fi
            cli_ctx docker compose _ exec $DEFAULT_OPTIONS "$SERVICE_NAME" "$@"
        else
            if [ "$IS_QUIET" != "true" ]; then stdout --processing --ansi="90" --icon="$(capitalize $SERVICE_NAME) ○" "Not running, Launching an instance, Executing '$COMMAND_STR'"; fi
            cli_ctx docker compose _ run --rm $DEFAULT_OPTIONS $RUN_OPTIONS "$SERVICE_NAME" "$@"
        fi
    fi
}