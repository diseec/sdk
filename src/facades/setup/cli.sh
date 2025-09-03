#!/bin/bash

source_once "$KIT_SRC_DIR/facades/setup/index.sh"

c=$1; shift; case $c in
    rep|repository) src_fac_set_repository "$@" ;;
    pre|prettier) src_fac_set_prettier "$@" ;;
    upd|update) src_fac_set_cmd_update "$@" ;;
    glo|globally) src_fac_set_globally "$@" ;;
    sys|system) c=$1; shift; case $c in
        dep|dependency-check)
            src_fac_set_check_system_dependencies
        ;;
        ins|install)
            src_fac_set_install_system_dependencies
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
            "    rep|repository   " "Setup repository (install toolchain and scaffold)" \
            "    pre|prettier  " "Install or configure Prettier" \
            "    sys|system    " "System dependency helpers (see 'cli setup system -h')" \
            "    upd|update    " "Setup update hooks" \
            "    glo|globally  " "Install tools globally for developer machine" \
            "$@"
        ;;
    fun|function) "$@" ;;
    *) if [ ! -z "$c" ]; then logit -e "Unknown command: '$c'"; fi ;;
esac
