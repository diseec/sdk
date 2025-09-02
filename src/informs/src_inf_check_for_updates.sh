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

    # Check if version changed or if repo/modules are behind
    if fac_set_has_version_changed; then
        version_info=$(fac_set_get_version_info)
        confirm "New kit version available $version_info, download updates?" cli_main update --recursive
    elif [ -d "$ROOT_DIR/.git" ]; then
        # Check if the main repository is behind
        current_branch=$(_git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)
        if [ $? -eq 0 ] && [ -n "$current_branch" ]; then
            _git -C "$ROOT_DIR" fetch origin
            local_commit=$(_git -C "$ROOT_DIR" rev-parse @)
            remote_commit=$(_git -C "$ROOT_DIR" rev-parse "@{u}")
            
            if [ $? -eq 0 ] && [ "$local_commit" != "$remote_commit" ]; then
                confirm "Repository is behind the remote branch, apply update?" cli_main update --recursive
            else
                # Check if any of the selected modules are behind
                modules_behind=false
                
                check_module_status() {
                    local module="$1"
                    local module_path="$2"
                    local full_path="$ROOT_DIR/$module_path"
                    
                    if [ -d "$full_path/.git" ]; then
                        _git -C "$full_path" fetch origin
                        local_commit=$(_git -C "$full_path" rev-parse @)
                        remote_commit=$(_git -C "$full_path" rev-parse "@{u}")
                        
                        if [ $? -eq 0 ] && [ "$local_commit" != "$remote_commit" ]; then
                            modules_behind=true
                            return 1  # Exit the loop early
                        fi
                    fi
                }
                fac_wor_foreach_selected_module check_module_status
                
                if $modules_behind; then
                    confirm "Modules are behind their remote branches, update them?" cli_main update --recursive
                fi
            fi
        fi
    fi
}
