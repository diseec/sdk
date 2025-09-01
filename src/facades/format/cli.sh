#!/bin/bash

c=$1; shift; case $c in
    pre|prettier) fac_for_prettier "$@" ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi 37 'Formatting')" "" \
            "$(ansi 37 'Usage:    cli format <command> [options]')" "" "" "" \
            "    pre|prettier          " "Run Prettier on repository (respects .prettierrc)" \
            "    --check               " "Run in check mode (no changes, exit non-zero if unformatted)" \
            "    --write               " "Write formatted files (default)" \
            "    -h|--help             " "Show this help message" \
            "$@"
    ;;
    *)
        display_help "" "" \
            "$(ansi 37 'Formatting')" "" \
            "$(ansi 37 'Usage:    cli format <command> [options]')" "" \
            "    pre|prettier          " "Run Prettier on repository (respects .prettierrc)" \
            "    --check               " "Run in check mode (no changes, exit non-zero if unformatted)" \
            "    --write               " "Write formatted files (default)" \
            "    -h|--help             " "Show this help message" \
            "$@"
    ;;
esac
