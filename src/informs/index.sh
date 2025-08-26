#!/bin/bash

c=$1; shift; case $c in
    csd|check-system-dependencies) . $KIT_SRC_DIR/informs/check-system-dependencies.sh "$@" ;;
    cic|check-internet-connection) . $KIT_SRC_DIR/informs/check-internet-connection.sh "$@" ;;
    fdm|forbid-dev-on-main) . $KIT_SRC_DIR/informs/forbid-dev-on-main.sh "$@" ;;
    sbs|_status-branch-status) . $KIT_SRC_DIR/informs/_status-branch-status.sh "$@" ;;
    cfu|check-for-updates) . $KIT_SRC_DIR/informs/check-for-updates.sh "$@" ;;
    *) display_help "" "" \
        "$(color 30 'Inform Commands')" "" \
        "    csd|check-system-dependencies   " "Check for missing system dependencies" \
        "    cic|check-internet-connection   " "Check if the internet connection is active" \
        "    fdm|forbid-dev-on-main          " "Warn if on 'main' branch" \
        "    sbs|_status-branch-status       " "Show local vs remote branch status" \
        "    cfu|check-for-updates           " "Check for CLI updates and notify"
    ;;
esac