#!/bin/bash

src_inf_summary_branch_status() {
    if cli_main internet is-online; then
        _git fetch origin
    else
        logit --ansi="31" --icon="⊘" "Disconnected, cannot fetch branch status..."
    fi

    local_commit=$(_git rev-parse @)
    remote_commit=$(_git rev-parse @{u})
    base_commit=$(_git merge-base @ @{u})

    if [ "$local_commit" != "$remote_commit" ]; then
        if [ "$local_commit" = "$base_commit" ]; then
            logit --ansi="34" --icon="↑" "Local branch is behind 'origin/$current_branch'"
        else
            logit --ansi="31" --icon="⇄" "Branch has diverged from 'origin/$current_branch'!"
        fi
    fi
}
