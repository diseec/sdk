#!/bin/bash

c=$1; shift; case "$c" in
    ini|init) fac_wor_init "$@" ;;
    sel|select) fac_wor_select "$@" ;;
    sta|status) fac_wor_status "$@" ;;
    con|config) cli_main config --scope=workspace "$@" ;;
    hel|help|--help|-h) display_help  "" "" \
        "$(ansi 37 'Workspace Commands')" "" \
        "    ini|init      " "Initialize workspace configuration" \
        "    sel|select    " "Select submodules for workspace" \
        "    sta|status    " "Show current workspace configuration" \
        "    con|config    " "Manage workspace configuration (get/set/delete/list)"
    ;;
    *) if [ ! -z "$c" ]; then echo "workspace: Unknown command: '$c'"; fi ;;
esac