#!/bin/bash

# =============================================================================
# GIT UTILITIES
# =============================================================================
# Git-related functions and operations

sdk_boo_env_uti_get_git_dir() {
    if [ "$D_SDK_CLI_EXECUTED" = "true" ] || [ -z "$D_CTX_DIR_HOST" ]; then return 0; fi

    find_git_dir_for() {
        local target="$1"
        local git_dir_or_file="$target/.git"

        if [ -d "$git_dir_or_file" ]; then
            # Standard git repo
            echo "$git_dir_or_file" 
            return 0
        fi

        if [ ! -f "$git_dir_or_file" ]; then
            # echo "error: '$git_dir_or_file' is not a valid git reference"
            return 0
        fi

        # Submodule or worktree: .git is a file pointing to actual gitdir
        
        local gitdir_ref=$(awk -F': ' '/^gitdir:/ {print $2}' "$git_dir_or_file")

        if [ "$IS_IN_SDK_CONTAINER" != "true" ]; then
            echo "$target/$gitdir_ref"
            return 0
        fi

        # Conclusion is it's running in container, then we:

        if [ "$target" = "$D_CTX_DIR_CONTAINER" ]; then
            echo "$D_GIT_DIR_CONTAINER"
            return 0
        else
            # remove any leading ../ or ./ and strip up-to-and-including ".git/"
            module_ref=$(echo "$gitdir_ref" | awk -F'.git/' '{print $2}')
            echo "$D_GIT_DIR_CONTAINER/$module_ref"
            return 0
        fi

        echo "error: no git reference found"
    }

    if [ "$D_CTX_DIR_HOST" != "$D_SDK_DIR" ]; then
        find_git_dir_for "$D_CTX_DIR_HOST"
        return
    else
        find_git_dir_for "$D_CTX_DIR"
        return
    fi
}

sdk_boo_env_uti_get_git_config_file() {
    local git_dir
    git_dir=$(sdk_boo_env_uti_get_git_dir)
    if [ -d "$git_dir" ]; then
        echo "$git_dir/config"
    fi
}

sdk_boo_env_uti_get_repo_url() {
    local git_config_file
    git_config_file=$(sdk_boo_env_uti_get_git_config_file)
    
    if [ -f "$git_config_file" ]; then
        awk -F' = ' '/\[remote "origin"\]/ {found=1} found && /url =/ {print $2; exit}' "$git_config_file"
    fi
}

sdk_boo_env_uti_get_repo_name() {
    local repo_url
    repo_url=$(sdk_boo_env_uti_get_repo_url)
    
    if [ -n "$repo_url" ]; then
        # Remove trailing .git if present
        basename "${repo_url%.git}"
    fi
}

sdk_boo_env_uti_get_current_branch() {
    # Replacement for: git rev-parse --abbrev-ref HEAD
    local git_dir="$D_CTX_DIR/.git"
    local head_file=""
    
    if [ -d "$git_dir" ]; then
        # Standard git repo
        head_file="$git_dir/HEAD"
    elif [ -f "$git_dir" ]; then
        # Submodule or worktree: .git is a file pointing to actual gitdir
        local gitdir_path="$D_CTX_DIR/$(awk -F': ' '/^gitdir:/ {print $2}' "$git_dir")"
        if [ -n "$gitdir_path" ] && [ -f "$gitdir_path/HEAD" ]; then
            head_file="$gitdir_path/HEAD"
        fi
    fi
    
    if [ -f "$head_file" ]; then
        local head_content
        head_content=$(cat "$head_file")
        if [ "${head_content#ref: refs/heads/}" != "$head_content" ]; then
            # Extract branch name from "ref: refs/heads/branch-name"
            echo "${head_content#ref: refs/heads/}"
        else
            # Detached HEAD state - return first 7 chars of commit hash
            echo "${head_content:0:7}"
        fi
    else
        echo "unknown"
    fi
}
