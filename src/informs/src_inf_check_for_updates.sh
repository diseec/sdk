#!/bin/bash

src_inf_check_for_updates() {
    if ! cli_main internet is-online; then
        logit --ansi="31" --icon="⊘" "Disconnected, skipping update check..."
        return 0
    fi

    # Skip if we're just running version or help commands
    if [ "$command" = "version" ] || [ "$command" = "--version" ] || [ "$command" = "help" ] || [ "$command" = "update" ]; then
        return 0
    fi

    if cli_main informs src_inf_check_for_updates_kit; then
        local kit_update_available="true"
    fi
    if cli_main informs src_inf_check_for_updates_repo; then
        local repo_update_available="true"
    fi

    if [ "$kit_update_available" = "true" ] || [ "$repo_update_available" = "true" ]; then
        confirm "Apply updates now?" cli_main update --recursive
    fi
}
