#!/bin/bash

sdk_fac_inf_summary_branch_status() {
    if cli_ctx internet is-online; then
        _git fetch origin
    else
        stdout --ansi="31" --icon="⊘" "Disconnected, cannot fetch branch status..."
    fi

    local_commit=$(_git rev-parse @)
    remote_commit=$(_git rev-parse @{u})
    base_commit=$(_git merge-base @ @{u})

    if [ "$local_commit" != "$remote_commit" ]; then
        if [ "$local_commit" = "$base_commit" ]; then
            stdout --ansi="34" --icon="↑" "Local branch is behind 'origin/$current_branch'"
        else
            stdout --ansi="31" --icon="⇄" "Branch has diverged from 'origin/$current_branch'!"
        fi
    fi
}
