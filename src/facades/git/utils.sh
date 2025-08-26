#!/bin/bash

# =============================================================================
# GIT UTILITIES
# =============================================================================
# Git-related functions and operations

get_git_config_file() {
    local git_dir="$ROOT_DIR/.git"
    local git_config_file=""
    
    if [ -d "$git_dir" ]; then
        # Standard git repo
        git_config_file="$git_dir/config"
    elif [ -f "$git_dir" ]; then
        # Submodule or worktree: .git is a file pointing to actual gitdir
        local gitdir_path="$ROOT_DIR/$(awk -F': ' '/^gitdir:/ {print $2}' "$git_dir")"
        if [ -n "$gitdir_path" ] && [ -f "$gitdir_path/config" ]; then
            git_config_file="$gitdir_path/config"
        fi
    fi
    
    echo "$git_config_file"
}

get_repo_url() {
    local git_config_file
    git_config_file=$(get_git_config_file)
    
    if [ -f "$git_config_file" ]; then
        awk -F' = ' '/\[remote "origin"\]/ {found=1} found && /url =/ {print $2; exit}' "$git_config_file"
    fi
}

get_repo_name() {
    local repo_url
    repo_url=$(get_repo_url)
    
    if [ -n "$repo_url" ]; then
        # Remove trailing .git if present
        basename "${repo_url%.git}"
    fi
}

get_current_branch() {
    # Replacement for: git rev-parse --abbrev-ref HEAD
    local git_dir="$ROOT_DIR/.git"
    local head_file=""
    
    if [ -d "$git_dir" ]; then
        # Standard git repo
        head_file="$git_dir/HEAD"
    elif [ -f "$git_dir" ]; then
        # Submodule or worktree: .git is a file pointing to actual gitdir
        local gitdir_path="$ROOT_DIR/$(awk -F': ' '/^gitdir:/ {print $2}' "$git_dir")"
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
