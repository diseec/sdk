#!/bin/bash

. $KIT_SRC_DIR/cmds/update.sh
. $KIT_SRC_DIR/cmds/workspace.sh

# Skip if we're just running version or help commands
if [ "$command" = "version" ] || [ "$command" = "--version" ] || [ "$command" = "help" ] || [ "$command" = "update" ]; then
    return 0
fi

# Check if version changed or if repo/modules are behind
if has_version_changed; then
    message 46 "UPDATE" "New updates available!"
    ask_to_run_command "Apply updates now?" "$CLI" update
elif [ -d "$ROOT_DIR/.git" ]; then
    # Check if the main repository is behind
    current_branch=$(_git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)
    if [ $? -eq 0 ] && [ -n "$current_branch" ]; then
        _git -C "$ROOT_DIR" fetch origin
        local_commit=$(_git -C "$ROOT_DIR" rev-parse @)
        remote_commit=$(_git -C "$ROOT_DIR" rev-parse "@{u}")
        
        if [ $? -eq 0 ] && [ "$local_commit" != "$remote_commit" ]; then
            message 33 "UPDATE" "Repository is behind the remote branch!"
            ask_to_run_command "Apply updates now?" "$CLI" update
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
            
            foreach_selected_module_with_callback check_module_status
            
            if $modules_behind; then
                message 33 "UPDATE" "Modules are behind their remote branches!"
                ask_to_run_command "Apply updates now?" "$CLI" update
            fi
        fi
    fi
fi

