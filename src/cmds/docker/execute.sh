#!/bin/bash

SERVICE_NAME=$1; shift;
IS_SILENT=""

while [ $# -gt 0 ]; do case "$1" in
    --no-message) IS_SILENT="true"; shift;;
*) break;; esac; done;

if [ -n "$CI" ]; 
    then OPTIONS="-e CI=true";
    else OPTIONS="-it";
fi

if [ "$IS_IN_CONTAINER" = "true" ]; then
    if [ "$IS_SILENT" != "true" ]; then message 40 "▶ $SERVICE_NAME" "Inside container, Executing command .."; fi
    "$@"
else
    if _docker compose ps -q "$SERVICE_NAME" | grep -q .; then
        if [ "$IS_SILENT" != "true" ]; then message 40 "● $SERVICE_NAME" "Already running, Executing command .."; fi
        _docker compose exec $OPTIONS "$SERVICE_NAME" "$@"
    else
        if [ "$IS_SILENT" != "true" ]; then message 40 "○ $SERVICE_NAME" "Not running, Launching an instance .."; fi
        _docker compose run --rm --no-deps $OPTIONS "$SERVICE_NAME" "$@"
    fi
fi
