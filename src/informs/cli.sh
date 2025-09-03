#!/bin/bash

source_once "$KIT_DIR/src/informs/index.sh"

c=$1; shift; case $c in
    src_inf_check_for_updates) src_inf_check_for_updates "$@" ;;
    src_inf_check_for_updates_kit) force_safe informs $c "$@" || src_inf_check_for_updates_kit "$@" ;;
    src_inf_check_for_updates_repo) force_safe informs $c "$@" || src_inf_check_for_updates_repo "$@" ;;

    src_inf_check_internet_connection) force_safe informs $c "$@" || src_inf_check_internet_connection "$@" ;;
    src_inf_check_system_dependencies) src_inf_check_system_dependencies "$@" ;;
    src_inf_forbid_dev_on_main) force_safe informs $c "$@" || src_inf_forbid_dev_on_main "$@" ;;
    src_inf_summary_branch_status) force_safe informs $c "$@" || src_inf_summary_branch_status "$@" ;;
esac
