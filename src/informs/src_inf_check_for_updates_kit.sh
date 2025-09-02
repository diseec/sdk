#!/bin/bash

src_inf_check_for_updates_kit() {
    # Check if version changed or if repo/modules are behind
    if fac_set_has_version_changed; then
        version_info=$(fac_set_get_version_info)
        logit --ansi="34" --icon="↓" "New kit version available $version_info!"
        return 0
    else
        return 1
    fi
}
