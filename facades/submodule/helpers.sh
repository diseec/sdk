#!/bin/bash

# Function to extract information from the path format
sdk_fac_sub_parse_path_format() {
    local full_path="$1"

    # Validate the full path format
    if [[ ! "$full_path" =~ ^([^/]+)/([^/]+)$ ]]; then
        stdout -e "Invalid path format. Must be 'type/path/to/reponame', provided: '$full_path'"
        return 1
    fi

    # Split the path into components
    IFS='/' read -ra path_components <<< "$full_path"
    
    # Must have at least 2 segments (type/reponame)
    if [[ ${#path_components[@]} -lt 2 ]]; then
        stdout -e "Invalid path format. Must be at least 'type/reponame'"
        return 1
    fi
    
    # Extract type (first component)
    local type="${path_components[0]}"
    
    # Extract repo name (last component)
    local repo_name="${path_components[${#path_components[@]}-1]}"
    
    # # Build the relative path (everything except the repo name)
    local path_prefix=()
    for ((i=0; i<${#path_components[@]}-1; i++)); do
        path_prefix+=("${path_components[$i]}")
    done
    
    # Join the path components for the target directory
    local type_dir="$D_CTX_DIR/$(IFS='/'; echo "${path_prefix[*]}")"

    if [[ -z "$type" ]]; then
        stdout -e "Type is required, please specify as type/path/to/reponame"
        return 1
    fi
    
    if [[ -z "$repo_name" ]]; then
        stdout -e "Repository name is required, please specify as type/path/to/reponame"
        return 1
    fi

    # Ensure target directory exists if specified
    if [[ -n "$type_dir" ]]; then
        ensure_dir_owned "$type_dir"
    fi

    # Return values
    echo "$type" "$repo_name" "$type_dir"

    return 0
}

# Process all submodules from .gitmodules
sdk_fac_sub_fea_foreach_submodule() {
    local action_func="$1"
    
    # Extract submodule info from .gitmodules
    if [ ! -f "$D_CTX_DIR/.gitmodules" ]; then
        stdout -w "No .gitmodules file found"
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
