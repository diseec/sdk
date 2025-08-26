#!/bin/bash

SRC facades/ai/index.sh

# Generate commit message using AI
generate_commit_message() {
    local diff_output="$(_git diff --staged)"
  
    if [ -z "$diff_output" ]; then
      # message 43 "!" "No staged changes found. Staging all changes..."
      _git add -A
      diff_output="$(_git diff --staged)"
      
      if [ -z "$diff_output" ]; then
        message 31 "ERROR" "No changes to commit"
        return 1
      fi
    fi
  
    # message 34 "INFO" "Generating commit message..."
  
    # Limit diff size to avoid API limits
    local diff_summary="$(_git diff --staged --stat)"
    local diff_preview="$(_git diff --staged | head -n 300)"
  
    # Use AI to generate commit message, with fallback
    if . "$@" ai ai_is_available; then
        ai_generate_commit_message "$diff_summary" "$diff_preview"
    else
        # Fallback: generate simple commit message based on modified files
        local files_changed=$(_git diff --staged --name-only | sort | uniq)
        ai_fallback_commit_message "$files_changed"
    fi
}

# Handle detached HEAD state
warn_detached_head() {
  # Check if we're in detached HEAD state
  if ! _git symbolic-ref HEAD >/dev/null 2>&1; then
    message 41 "!" "Currently in detached HEAD state"
    
    # Check if there are any changes
    if [ -n "$(_git status --porcelain)" ]; then
      message 41 "DANGER" "You have uncommitted changes in detached HEAD state"
      return 1
    fi
  fi
  
  return 0
}

# Commit all changes with AI-generated message
cmd_git_commit() {
  # Handle detached HEAD state first
  warn_detached_head
  if [ $? -ne 0 ]; then return 1; fi
  
  # Don't allow commits directly to main
  if [ "$CURRENT_BRANCH" = "main" ]; then
    message 41 "!" "Committing to main branch is forbidden.\nPlease create a feature branch first and move your changes."
    echo -n "Type 'MAIN' to confirm (or anything else to cancel): "
    read confirmation
    if [ "$confirmation" != "MAIN" ]; then
      echo "Operation cancelled."
      return 1
    fi
  fi
  
  # Stage all changes
  _git add -A
  if [ $? -ne 0 ]; then
    message 31 "ERROR" "Failed to stage changes."
    return 1
  fi

  # Check if there are any changes to commit
  if [ -z "$(_git diff --staged)" ]; then
    message 43 "!" "No changes to commit"
    return 1
  fi

  # Generate commit message
  local commit_msg=$(generate_commit_message)
  if [ -z "$commit_msg" ]; then
    message 31 "ERROR" "Failed to generate commit message."
    return 1
  fi
  
  echo "$commit_msg" > /tmp/commit-msg.txt
  _git commit -F /tmp/commit-msg.txt
  if [ $? -ne 0 ]; then
    message 31 "ERROR" "Failed to commit changes."
    return 1
  fi
  rm /tmp/commit-msg.txt
  
  return 0
}

