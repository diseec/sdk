#!/bin/bash

# Generate commit message using AI
generate_commit_message() {
  local OPENAI_API_KEY="$("$CLI" on-bench secret export OPENAI_API_KEY)"
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
  
  # Use OpenAI API if available, otherwise fall back to a simpler approach
  if command -v curl >/dev/null 2>&1 && [ -n "$OPENAI_API_KEY" ]; then
    local prompt="Generate a concise, descriptive commit message for the following code changes.

Summary of changes:
${diff_summary}

Preview of changes:
${diff_preview}

Please format the response as a commit message with a short title (max 50 chars) on the first line, then a blank line, then bullet points with details if needed."
    
    # Escape the prompt for JSON
    local escaped_prompt=$(echo "$prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' '\r' | sed 's/\r/\\n/g')
    
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}], \"temperature\": 0.7}")

    # Check if the response contains an error
    if echo "$response" | grep -q '"error"'; then
      message 31 "ERROR" "OpenAI API error. Using fallback method."
      # Fall back to simple commit message
      local files_changed=$(_git diff --staged --name-only | sort | uniq)
      local num_files=$(echo "$files_changed" | wc -l | tr -d ' ')
      local main_file=$(echo "$files_changed" | head -1)
      
      if [ "$num_files" -eq 1 ]; then
        echo "Update $main_file"
      else
        echo "Update $num_files files"
      fi
    else
      # Extract the content from the response
      echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$response" | grep -o '"content":"[^"]*"' | sed 's/"content":"//g' | sed 's/"$//g' | sed 's/\\n/\n/g'
    fi
  else
    # Fallback: generate simple commit message based on modified files
    local files_changed=$(_git diff --staged --name-only | sort | uniq)
    local num_files=$(echo "$files_changed" | wc -l | tr -d ' ')
    local main_file=$(echo "$files_changed" | head -1)
    local file_type=$(echo "$main_file" | grep -o '\.[^.]*$' | tr -d '.')
    
    if [ "$num_files" -eq 1 ]; then
      echo "Update $main_file"
    else
      echo "Update $num_files files"
      echo ""
      echo "Modified files:"
      echo "$files_changed" | sed 's/^/- /'
    fi
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
    echo -n "Type 'PUSH TO MAIN' to confirm (or anything else to cancel): "
    read confirmation
    if [ "$confirmation" != "PUSH TO MAIN" ]; then
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


# Create a new PR or update existing one
cmd_git_commit_get_report() {
  if check_gh_cli; then
    local pr_link=$(_gh pr view "$(has_open_pr)" --json url -q .url)
  fi
  local commit_link="https://github.com/$ORG_NAME/$REPO_NAME/commit/$(_git rev-parse HEAD)"

  # Commit changes
  echo ""
  message 34 "✨" "Excellent! Here's the summary to use in daily insights:"
  echo ""
  echo ""
  echo -e " \033[36mDATE $(date +'%Y-%m-%d')\033[0m"
  echo -e " \033[36mDEVE $(_git config user.name)\033[0m"
  echo -e " \033[36mEMAI $(_git config user.email)\033[0m"
  echo -e " \033[36mREPO $REPO_NAME\033[0m"
  echo -e " \033[36mBRAN $CURRENT_BRANCH\033[0m"
  echo -e " \033[36mCOMM \033[4m$commit_link\033[24m\033[0m"
  echo -e " \033[36mPULL \033[4m$pr_link\033[24m\033[0m"
  echo ""
  echo -e "\033[36m--------------------\033[0m"
  echo ""
  echo -e " \033[36m$(_git log -1 --pretty=%B)\033[0m"
  echo ""
  echo -e "\033[36m--------------------\033[0m"
  echo ""
  echo -e "\033[36m$(_git diff HEAD~1 --stat)\033[0m"
  echo ""
  echo ""
}

