#!/bin/bash

# # Generate commit message using AI
# sdk_fac_git_cmd_generate_commit_message() {
#     local work_focus="$1"
#     local commit_message=""
#     local diff_output="$(_git diff --staged)"
#     local exit_code=0
  
#     if [ -z "$diff_output" ]; then
#         stdout -l --processing "No staged changes found. Staging all changes"
#         _git add -A
#         diff_output="$(_git diff --staged)"
        
#         if [ -z "$diff_output" ]; then
#             stdout -e "No changes to commit"
#             return 1
#         fi
#     fi
  
#     # stdout -i "Generating commit message..."
  
#     # Limit diff size to avoid API limits
#     local diff_summary="$(_git diff --staged --stat)"
#     local diff_preview="$(_git diff --staged | head -n 300)"
  
#     # Use AI to generate commit message, with fallback
#     if cli_ctx ai function sdk_fac_ai_is_available; then
#         # push the diffs to temp files
#         local diff_summary_file=$(mktemp)
#         local diff_preview_file=$(mktemp)

#         echo "$diff_summary" > "$diff_summary_file"
#         echo "$diff_preview" > "$diff_preview_file"
        
#         commit_message="$(cli_ctx ai generate commit "$diff_summary_file" "$diff_preview_file" "$work_focus")"
#         exit_code=$?
#     else
#         # Fallback: generate simple commit message based on modified files
#         local files_changed=$(_git diff --staged --name-only | sort | uniq)
#         commit_message="$(cli_ctx ai function sdk_fac_ai_fallback_commit_message "$files_changed")"
#     fi

#     echo "$commit_message"
#     return $exit_code
# }

# Handle detached HEAD state
sdk_fac_git_cmd_warn_detached_head() {
  # Check if we're in detached HEAD state
  if ! _git symbolic-ref HEAD >/dev/null 2>&1; then
    stdout -e "Currently in detached HEAD state"
    
    # Check if there are any changes
    if [ -n "$(_git status --porcelain)" ]; then
      stdout -e "You have uncommitted changes in detached HEAD state"
      return 1
    fi
  fi
  
  return 0
}

# Commit all changes with AI-generated message
sdk_fac_git_cmd_commit() {
    # Handle detached HEAD state first
    sdk_fac_git_cmd_warn_detached_head
    if [ $? -ne 0 ]; then return 1; fi
  
    # Don't allow commits directly to main
    if [ "$D_CURRENT_BRANCH" = "main" ]; then
        stdout -e --icon="!" "Committing to main branch is forbidden, Please create a feature branch first and move your changes."
        stdin confirmation "Type 'MAIN' to confirm:"
        if [ "$confirmation" != "MAIN" ]; then
            stdout -l "Aborting commit to main branch."
            return 1
        fi
    fi
  
    # Stage all changes
    _git add -A
    if [ $? -ne 0 ]; then
        stdout -e "Failed to stage changes."
        return 1
    fi

    # Check if there are any changes to commit
    if [ -z "$(_git diff --staged)" ]; then
        stdout -w "No changes to commit"
        return 0
    fi

    if ! cli_ctx ai function sdk_fac_ai_init_interactive; then
        stdout -w "AI module loaded but API key not available"
    fi

    # Generate commit message with user confirmation
    stdout -a --processing "Writing commit message"
    local commit_msg=""
    local has_accepted_commit_message="false"
    stdin work_focus "What was main changes?" --default="I don't care"

    # while ! $has_accepted_commit_message; do
    #     commit_msg="$(sdk_fac_git_cmd_generate_commit_message "$work_focus")"

    #     if [ -z "$commit_msg" ]; then
    #         stdout -e "Failed to generate commit message."
    #         return 1
    #     fi
        
    #     # Display the generated message
    #     printf "\n"
    #     stdout -i "Generated commit message:"
    #     printf "\033[97m%s\033[0m\n\n" "$commit_msg"
        
    #     # Ask for confirmation
    #     if confirm "Do you want to use this commit message?"; then
    #         has_accepted_commit_message="true"
    #     else
    #         if ! confirm "Rewriting commit message?"; then
    #             stdout -l "Aborting commit."
    #             return 1
    #         fi
    #     fi
    # done
  
    if [ -z "$commit_msg" ]; then
        stdout -l "Using fallback commit message"
        commit_message="$work_focus"
    fi
        
    echo "$commit_msg" > /tmp/commit-msg.txt
    _git commit -F /tmp/commit-msg.txt
    if [ $? -ne 0 ]; then
        stdout -e "Failed to commit changes."
        return 1
    fi
    rm /tmp/commit-msg.txt
  
    return 0
}

