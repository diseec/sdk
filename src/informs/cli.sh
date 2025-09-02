#!/bin/bash

c=$1; shift; case $c in
    src_inf_check_for_updates) src_inf_check_for_updates "$@" ;;
    src_inf_check_internet_connection) src_inf_check_internet_connection "$@" ;;
    src_inf_check_system_dependencies) src_inf_check_system_dependencies "$@" ;;
    src_inf_forbid_dev_on_main) src_inf_forbid_dev_on_main "$@" ;;
    src_inf_summary_branch_status) src_inf_summary_branch_status "$@" ;;
esac
