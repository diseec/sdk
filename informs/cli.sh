#!/bin/bash

source_once "$D_SDK_DIR/informs/index.sh"

c=$1; shift; case $c in
    src_inf_check_for_updates) src_inf_check_for_updates "$@" ;;
    src_inf_check_for_updates_kit) source_safely informs $c "$@" || src_inf_check_for_updates_kit "$@" ;;
    src_inf_check_for_updates_repo) source_safely informs $c "$@" || src_inf_check_for_updates_repo "$@" ;;

    src_inf_check_internet_connection) source_safely informs $c "$@" || src_inf_check_internet_connection "$@" ;;
    src_inf_check_system_dependencies) src_inf_check_system_dependencies "$@" ;;
    src_inf_forbid_dev_on_main) source_safely informs $c "$@" || src_inf_forbid_dev_on_main "$@" ;;
    src_inf_summary_branch_status) source_safely informs $c "$@" || src_inf_summary_branch_status "$@" ;;
esac
