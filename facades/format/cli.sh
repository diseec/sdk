#!/bin/bash

source_once "$D_SDK_DIR/facades/format/index.sh"

c=$1; shift; case $c in
    pre|prettier) src_fac_for_prettier "$@" ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi 97 'Formatting')" "" \
            "$(ansi 97 'Usage:    cli format <command> [options]')" "" "" "" \
            "    pre|prettier          " "Run Prettier on repository (respects .prettierrc)" \
            "    --check               " "Run in check mode (no changes, exit non-zero if unformatted)" \
            "    --write               " "Write formatted files (default)" \
            "    -h|--help             " "Show this help message" \
            "$@"
    ;;
    fun|function) "$@" ;;
    *)
        display_help "" "" \
            "$(ansi 97 'Formatting')" "" \
            "$(ansi 97 'Usage:    cli format <command> [options]')" "" \
            "    pre|prettier          " "Run Prettier on repository (respects .prettierrc)" \
            "    --check               " "Run in check mode (no changes, exit non-zero if unformatted)" \
            "    --write               " "Write formatted files (default)" \
            "    -h|--help             " "Show this help message" \
            "$@"
    ;;
esac
