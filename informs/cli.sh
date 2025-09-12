#!/bin/bash

source_once "$D_SDK_DIR/informs/index.sh"

c=$1; shift; case $c in
    sdk_inf_check_for_updates) sdk_inf_check_for_updates "$@" ;;
    sdk_inf_check_for_updates_kit) sdk_inf_check_for_updates_kit "$@" ;;
    sdk_inf_check_for_updates_repo) sdk_inf_check_for_updates_repo "$@" ;;
    sdk_inf_check_internet_connection) sdk_inf_check_internet_connection "$@" ;;
    sdk_inf_forbid_dev_on_main) sdk_inf_forbid_dev_on_main "$@" ;;
    sdk_inf_summary_branch_status) sdk_inf_summary_branch_status "$@" ;;
    sdk_inf_check_system_dependencies) sdk_inf_check_system_dependencies "$@" ;;
esac
