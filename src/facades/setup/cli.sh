#!/bin/bash

c=$1; shift; case $c in
    pro|project) fac_set_project "$@" ;;
    pre|prettier) fac_set_prettier "$@" ;;
    upd|update) fac_set_update "$@" ;;
    glo|globally) fac_set_globally "$@" ;;
    sys|system) c=$1; shift; case $c in
        dep|dependency-check)
            fac_set_check_system_dependencies
        ;;
        ins|install)
            fac_set_install_system_dependencies
        ;;
        hel|help|--help|-h)
            display_help "" "" \
                "$(ansi 97 'System Setup')" "" \
                "$(ansi 97 'Usage:    cli setup system <command>')" "" "" "" \
                "    dep|dependency-check    " "Check system dependencies required by the project" \
                "    ins|install             " "Install missing system dependencies defined in project metadata" \
                "    -h|--help               " "Show this help message" \
                "$@"
        ;;
    esac ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi 97 'Setup Commands')" "" \
            "$(ansi 97 'Usage:    cli setup <command> [options]')" "" \
            "    pro|project   " "Setup project (install toolchain and scaffold)" \
            "    pre|prettier  " "Install or configure Prettier" \
            "    sys|system    " "System dependency helpers (see 'cli setup system -h')" \
            "    upd|update    " "Setup update hooks" \
            "    glo|globally  " "Install tools globally for developer machine" \
            "$@"
        ;;
    *) if [ ! -z "$c" ]; then echo "Unknown command: '$c'"; fi ;;
esac
