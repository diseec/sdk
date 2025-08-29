#!/bin/bash

c=$1; shift; case $c in
    pre|prettier) fac_dev_prettier "$@" ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(color 30 'Formatting')" "" \
            "$(color 30 'Usage:    cli format <command> [options]\\n')" "" \
            "    pre|prettier          " "Run Prettier on repository (respects .prettierrc)" \
            "    --check               " "Run in check mode (no changes, exit non-zero if unformatted)" \
            "    --write               " "Write formatted files (default)" \
            "    -h|--help             " "Show this help message" \
            "$@"
    ;;
    *)
        display_help "" "" \
            "$(color 30 'Formatting')" "" \
            "$(color 30 'Usage:    cli format <command> [options]\n')" "" \
            "    pre|prettier          " "Run Prettier on repository (respects .prettierrc)" \
            "    --check               " "Run in check mode (no changes, exit non-zero if unformatted)" \
            "    --write               " "Write formatted files (default)" \
            "    -h|--help             " "Show this help message" \
            "$@"
    ;;
esac
