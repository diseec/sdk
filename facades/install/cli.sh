#!/bin/bash

source_once "$D_SDK_DIR/facades/install/index.sh"

c=$1; shift; case $c in
    pat|patch) sdk_fac_ins_sdk "$@" ;;
    rep|repository) sdk_fac_ins_repository "$@" ;;
    pre|prettier) sdk_fac_ins_prettier "$@" ;;
    upd|update) sdk_fac_ins_cmd_update "$@" ;;
    glo|globally) sdk_fac_ins_globally "$@" ;;
    sys|system) c=$1; shift; case $c in
        dep|dependency-check)
            sdk_fac_ins_check_system_dependencies
        ;;
        ins|install)
            sdk_fac_ins_install_system_dependencies
        ;;
        hel|help|--help|-h)
            display_help "" "" \
                "$(ansi 97 'System Setup')" "" \
                "$(ansi 97 'Usage:    cli install system <command>')" "" "" "" \
                "    dep|dependency-check    " "Check system dependencies required by the project" \
                "    ins|install             " "Install missing system dependencies defined in project metadata" \
                "    -h|--help               " "Show this help message" \
                "$@"
        ;;
    esac ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi 97 'Setup Commands')" "" \
            "$(ansi 97 'Usage:    cli install <command> [options]')" "" \
            "    rep|repository   " "Setup repository (install toolchain and scaffold)" \
            "    pre|prettier  " "Install or configure Prettier" \
            "    sys|system    " "System dependency helpers (see 'cli install system -h')" \
            "    upd|update    " "Setup update hooks" \
            "    glo|globally  " "Install tools globally for developer machine" \
            "$@"
        ;;
    fun|function) "$@" ;;
    *) if [ ! -z "$c" ]; then logit -e "Unknown command: '$c'"; fi ;;
esac
