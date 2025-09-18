#!/bin/bash

sdk_fac_inf_check_for_updates_kit() {
    # Check if version changed or if repo/modules are behind
    if cli_ctx install function sdk_fac_ins_has_version_changed; then
        version_info=$(cli_ctx install function sdk_fac_ins_get_version_info)
        stdout --ansi="34" --icon="↓" "New sdk version available $version_info!"
        return 0
    else
        return 1
    fi
}
