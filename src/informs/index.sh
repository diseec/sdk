#!/bin/bash

c=$1; shift; case $c in
    csd|check-system-dependencies) source "$KIT_SRC_DIR/informs/check-system-dependencies.sh" "$@" ;;
    cic|check-internet-connection) source "$KIT_SRC_DIR/informs/check-internet-connection.sh" "$@" ;;
    fdm|forbid-dev-on-main) source "$KIT_SRC_DIR/informs/forbid-dev-on-main.sh" "$@" ;;
    sbs|summary-branch-status) source "$KIT_SRC_DIR/informs/summary-branch-status.sh" "$@" ;;
    cfu|check-for-updates) source "$KIT_SRC_DIR/informs/check-for-updates.sh" "$@" ;;
    *) display_help "" "" \
        "$(color 30 'Inform Commands')" "" \
        "    csd|check-system-dependencies   " "Check for missing system dependencies" \
        "    cic|check-internet-connection   " "Check if the internet connection is active" \
        "    fdm|forbid-dev-on-main          " "Warn if on 'main' branch" \
        "    sbs|summary-branch-status       " "Show local vs remote branch status" \
        "    cfu|check-for-updates           " "Check for cli_main updates and notify"
    ;;
esac