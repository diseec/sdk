#!/bin/bash

sdk_inf_check_for_updates_repo() {
    # Check if the main repository is behind
    current_branch=$(_git -C "$D_CTX_DIR" rev-parse --abbrev-ref HEAD)

    if [ $? -eq 0 ] && [ -n "$current_branch" ]; then
        _git -C "$D_CTX_DIR" fetch origin
        local_commit=$(_git -C "$D_CTX_DIR" rev-parse @)
        remote_commit=$(_git -C "$D_CTX_DIR" rev-parse "@{u}")
        
        if [ $? -eq 0 ] && [ "$local_commit" != "$remote_commit" ]; then
            logit --ansi="34" --icon="↓" "New commits available in $current_branch"
            return 0
        else
            # Check if any of the selected modules are behind
            modules_behind=false
            
            check_module_status() {
                local module="$1"
                local module_path="$2"
                local full_path="$D_CTX_DIR/$module_path"
                cd "$full_path"
                _git -C "$full_path" fetch origin
                local_commit=$(_git -C "$full_path" rev-parse @)
                remote_commit=$(_git -C "$full_path" rev-parse "@{u}")
                
                if [ $? -eq 0 ] && [ "$local_commit" != "$remote_commit" ]; then
                    modules_behind=true
                    return 1  # Exit the loop early
                fi
            }
            cli_ctx submodule foreach check_module_status
            
            if $modules_behind; then
                logit --ansi="34" --icon="↓" "New commits available in one or more selected modules"
                return 0
            fi
        fi
    fi
}
