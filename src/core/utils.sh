#!/bin/bash

cli_main() {
    source "$CLI_MAIN" "$@"
}

cli_core() {
    source "$CLI_CORE" "$@"
}

force_safe() {
    if [ "$IS_IN_KIT_CONTAINER" = "true" ];
        then return 1
        else cli_main safely "$@"; return 0
    fi
}
