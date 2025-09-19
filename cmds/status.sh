#!/bin/bash

sdk_cmd_status() {
    mark_ctx_only
    # cli_ctx about
    # cli_ctx config summary
    # cli_ctx informs sdk_fac_inf_check_system_dependencies
    cli_ctx informs sdk_fac_inf_check_internet_connection
    cli_ctx git status
    cli_ctx informs sdk_fac_inf_check_for_updates
}
