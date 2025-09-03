#!/bin/bash

source_once "$KIT_SRC_DIR/facades/workspace/index.sh"

c=$1; shift; case "$c" in
    ini|init) src_fac_wor_init "$@" ;;
    sel|select) src_fac_wor_select "$@" ;;
    sta|status) src_fac_wor_status "$@" ;;
    con|config) cli_main config --scope=workspace "$@" ;;
    hel|help|--help|-h) display_help  "" "" \
        "$(ansi 97 'Workspace Commands')" "" \
        "    ini|init      " "Initialize workspace configuration" \
        "    sel|select    " "Select submodules for workspace" \
        "    sta|status    " "Show current workspace configuration" \
        "    con|config    " "Manage workspace configuration (get/set/delete/list)"
    ;;
    *) if [ ! -z "$c" ]; then echo "workspace: Unknown command: '$c'"; fi ;;
esac