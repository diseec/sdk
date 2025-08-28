#!/bin/bash

c=$1; shift; case $c in
    csd|check-system-dependencies) SRC_KIT informs/check-system-dependencies.sh "$@" ;;
    cic|check-internet-connection) SRC_KIT informs/check-internet-connection.sh "$@" ;;
    fdm|forbid-dev-on-main) SRC_KIT informs/forbid-dev-on-main.sh "$@" ;;
    sbs|status-branch-status) SRC_KIT informs/status-branch-status.sh "$@" ;;
    cfu|check-for-updates) SRC_KIT informs/check-for-updates.sh "$@" ;;
    *) display_help "" "" \
        "$(color 30 'Inform Commands')" "" \
        "    csd|check-system-dependencies   " "Check for missing system dependencies" \
        "    cic|check-internet-connection   " "Check if the internet connection is active" \
        "    fdm|forbid-dev-on-main          " "Warn if on 'main' branch" \
        "    sbs|status-branch-status       " "Show local vs remote branch status" \
        "    cfu|check-for-updates           " "Check for CLI updates and notify"
    ;;
esac