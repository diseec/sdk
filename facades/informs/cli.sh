#!/bin/bash

source_once "$D_SDK_DIR/facades/informs/index.sh"

c=$1; shift; case $c in
    sdk_fac_inf_check_for_updates) sdk_fac_inf_check_for_updates "$@" ;;
    sdk_fac_inf_check_for_updates_kit) sdk_fac_inf_check_for_updates_kit "$@" ;;
    sdk_fac_inf_check_for_updates_repo) sdk_fac_inf_check_for_updates_repo "$@" ;;
    sdk_fac_inf_check_internet_connection) sdk_fac_inf_check_internet_connection "$@" ;;
    sdk_fac_inf_forbid_dev_on_main) sdk_fac_inf_forbid_dev_on_main "$@" ;;
    sdk_fac_inf_summary_branch_status) sdk_fac_inf_summary_branch_status "$@" ;;
    sdk_fac_inf_check_system_dependencies) sdk_fac_inf_check_system_dependencies "$@" ;;
esac
