#!/bin/bash

# Process all submodules from .gitmodules
sdk_fac_sub_fea_foreach_submodule() {
    local action_func="$1"
    
    # Extract submodule info from .gitmodules
    if [ ! -f "$D_CTX_DIR/.gitmodules" ]; then
        logit -w "No .gitmodules file found"
        return 0
    fi
    
    local submodule_paths=()
    local submodule_names=()
    
    # Parse .gitmodules file to get all submodules
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[submodule\ \"([^\"]+)\" ]]; then
            local name="${BASH_REMATCH[1]}"
            # Read the next few lines to find the path
            local path=""
            local i=0
            while IFS= read -r subline && [ $i -lt 5 ]; do
                if [[ "$subline" =~ ^[[:space:]]*path[[:space:]]*=[[:space:]]*(.+) ]]; then
                    path="${BASH_REMATCH[1]}"
                    break
                fi
                ((i++))
            done < <(tail -n +$(($(grep -n "^\[submodule \"$name\"" "$D_CTX_DIR/.gitmodules" | cut -d: -f1) + 1)) "$D_CTX_DIR/.gitmodules" | head -n 5)
            
            if [ -n "$path" ]; then
                submodule_names+=("$name")
                submodule_paths+=("$path")
            fi
        fi
    done < "$D_CTX_DIR/.gitmodules"
    
    # Process each submodule
    for i in "${!submodule_names[@]}"; do
        local name="${submodule_names[$i]}"
        local path="${submodule_paths[$i]}"
        "$action_func" "$name" "$path"
    done
    
    return 0
}
