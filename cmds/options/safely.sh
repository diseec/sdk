#!/bin/bash

sdk_cmd_opt_safely() {
    mark_ctx_only

    local exit_code=""

    if [ "$IS_IN_SDK_CONTAINER" = "true" ]; then
        "$@"
        exit_code=$?
    elif [ "$D_IS_IN_CONTAINER" = "true" ]; then
        CONTAINER_ID=$(hostname 2>/dev/null || echo "unknown")
        stdout -e "Trying to run '$@' command in '$D_SDK_NAME' container, but already in a different container: $CONTAINER_ID" >&2
        return 1
    else
        stdout -l "Container only command, redirecting: $@"

        local stop_result="$(cli_ctx "$D_SDK_NAME" stop)";
        if [ $? -ne 0 ]; then
            echo "$stop_result"
            stdout -e "Failed to stop existing $D_SDK_NAME container"
            return 1
        fi

        cli_ctx "$D_SDK_NAME" run --quiet "$D_CLI_STUB_CONTAINER" "$@"; # when non-zero exit code, docker prints a empty line!
        exit_code=$?
    fi

    if [ $exit_code -ne 0 ]; then
        stdout -e "Failed to run command '$*' in $D_SDK_NAME container"
    fi

    return $exit_code

    # cli_ctx "$D_SDK_NAME" run "$D_CLI_STUB_CONTAINER" "$@"
    # if [ $? -ne 0 ]; then stdout -e "Failed to run command in $D_SDK_NAME container"; fi
}