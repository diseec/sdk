#!/bin/bash

src_inf_check_for_updates_kit() {
    # Check if version changed or if repo/modules are behind
    X
    if cli_main setup function src_fac_set_has_version_changed; then
    X 0
        version_info=$(cli_main setup function src_fac_set_get_version_info)
        logit --ansi="34" --icon="↓" "New kit version available $version_info!"
        return 0
    else
    X 1
        return 1
    fi
}
