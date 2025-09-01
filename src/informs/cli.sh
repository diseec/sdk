#!/bin/bash

c=$1; shift; case $c in
    csd|check-system-dependencies)   src_inf_check_system_dependencies "$@" ;;
    fdm|forbid-dev-on-main)          src_inf_forbid_dev_on_main "$@" ;;
    sbs|summary-branch-status)       src_inf_summary_branch_status "$@" ;;
    cfu|check-for-updates)           src_inf_check_for_updates "$@" ;;
    cic|check-internet-connection)   src_inf_check_internet_connection "$@" ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi 97 'Inform Commands')" "" \
        "    csd|check-system-dependencies   " "Check for missing system dependencies" \
        "    cic|check-internet-connection   " "Check if the internet connection is active" \
        "    fdm|forbid-dev-on-main          " "Warn if on 'main' branch" \
        "    sbs|summary-branch-status       " "Show local vs remote branch status" \
        "    cfu|check-for-updates           " "Check for cli_main updates and notify"
    ;;
    *) logger -e "Unknown command: '$c'" ;;
esac