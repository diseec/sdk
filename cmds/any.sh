#!/bin/bash

sdk_cmd_any() {
    if [[ -n "$c" ]]; then
        logit -e "Unknown command: '$c'";
        confirm "Show quick docs?" cli_ctx help; exit 1;
    else
        cli_ctx help; exit 1;
    fi
}
