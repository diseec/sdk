#!/bin/sh

_git() {
  $CLI $KIT_NAME exec $KIT_NAME --no-message git "$@"
}

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

# Check if GitHub CLI is installed
check_gh_cli() {
  if ! command -v gh >/dev/null 2>&1; then
    message 41 "error" "GitHub CLI (gh) is not installed. Please install it first:"
    message 43 "info" "  brew install gh   # For macOS"
    message 43 "info" "  Then authenticate: gh auth login"
    return 1
  fi
  
  # Check if authenticated
  if ! gh auth status >/dev/null 2>&1; then
    message 41 "error" "GitHub CLI is not authenticated. Please run: gh auth login"
    return 1
  fi
  
  return 0
}

# Generate commit message using AI
generate_commit_message() {
  local diff_output="$(git diff --staged)"
  
  if [ -z "$diff_output" ]; then
    message 33 "warn" "No staged changes found. Staging all changes..."
    git add -A
    diff_output="$(git diff --staged)"
    
    if [ -z "$diff_output" ]; then
      message 31 "error" "No changes to commit"
      return 1
    fi
  fi
  
  message 34 "ai" "Generating commit message..."
  
  # Limit diff size to avoid API limits
  local diff_summary="$(git diff --staged --stat)"
  local diff_preview="$(git diff --staged | head -n 300)"
  
  # Use OpenAI API if available, otherwise fall back to a simpler approach
  if command -v curl >/dev/null 2>&1 && [ -n "$OPENAI_API_KEY" ]; then
    local prompt="Generate a concise, descriptive commit message for the following code changes.\n\nSummary of changes:\n${diff_summary}\n\nPreview of changes:\n${diff_preview}\n\nPlease format the response as a commit message with a short title (max 50 chars) on the first line, then a blank line, then bullet points with details if needed."
    
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}], \"temperature\": 0.7}")
    
    echo "$response" | grep -o '"content":"[^"]*' | sed 's/"content":"//g' | sed 's/\\n/\n/g'
  else
    # Fallback: generate simple commit message based on modified files
    local files_changed=$(git diff --staged --name-only | sort | uniq)
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

# Get current branch name
get_current_branch() {
  git rev-parse --abbrev-ref HEAD
}

# Check if current branch has a PR
has_open_pr() {
  local branch="$(get_current_branch)"
  
  if check_gh_cli; then
    # Try to get PR number for current branch
    pr_number=$(gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null)
    if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
      echo "$pr_number"
      return 0
    fi
  else
    # Fallback: try to infer from GitHub API via git remote
    local remote_url=$(git remote get-url origin)
    local repo=$(echo "$remote_url" | sed -E 's/.*github.com[:\/](.*)\/(.*)(\.git)?/\1\/\2/')
    
    if [ -n "$repo" ]; then
      # This is a basic check that won't work for private repos without auth
      local api_url="https://api.github.com/repos/$repo/pulls?head=$branch"
      if command -v curl >/dev/null 2>&1; then
        local pr_data=$(curl -s "$api_url")
        if echo "$pr_data" | grep -q '"number":'; then
          local pr_number=$(echo "$pr_data" | grep -o '"number": [0-9]*' | head -1 | awk '{print $2}')
          echo "$pr_number"
          return 0
        fi
      fi
    fi
  fi
  
  return 1
}

# Commit all changes with AI-generated message and push
commit_and_push() {
  local branch="$(get_current_branch)"
  
  # Don't allow commits directly to main
  if [ "$branch" = "main" ]; then
    message 41 "error" "Cannot commit directly to main branch. Please create a feature branch first."
    return 1
  fi
  
  # Stage all changes
  git add -A
  
  # Generate commit message
  local commit_msg=$(generate_commit_message)
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  # Commit changes
  message 34 "git" "Committing changes with message:"
  message 36 "commit" "$commit_msg"
  echo "$commit_msg" > /tmp/commit-msg.txt
  git commit -F /tmp/commit-msg.txt
  rm /tmp/commit-msg.txt
  
  # Push to remote
  message 34 "git" "Pushing to remote..."
  git push -u origin "$branch"
  
  return 0
}

# Create a new PR or update existing one
create_or_update_pr() {
  local pr_number=$(has_open_pr)
  local branch="$(get_current_branch)"
  
  # Commit and push changes first
  commit_and_push
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  if [ -n "$pr_number" ]; then
    message 32 "pr" "Updated existing PR #$pr_number"
    
    # If gh CLI is available, provide a link
    if check_gh_cli; then
      local pr_url=$(gh pr view "$pr_number" --json url -q .url)
      message 36 "url" "$pr_url"
    fi
  else
    # Create a new PR
    message 34 "pr" "Creating new PR for branch: $branch"
    
    if check_gh_cli; then
      # Use last commit message as PR title/body
      local pr_title=$(git log -1 --pretty=%s)
      local pr_body=$(git log -1 --pretty=%b)
      
      if [ -z "$pr_body" ]; then
        pr_body="Changes in this PR:\n\n$(git diff --stat origin/main..HEAD)"
      fi
      
      # Create PR using GitHub CLI
      local pr_url=$(gh pr create --title "$pr_title" --body "$pr_body" --base main)
      
      message 32 "pr" "Created new PR:"
      message 36 "url" "$pr_url"
    else
      message 33 "pr" "Install GitHub CLI (gh) for automatic PR creation"
      message 33 "pr" "Create PR manually at: https://github.com/$(git remote get-url origin | sed -E 's/.*github.com[:\/](.*)\/(.*)(\.git)?/\1\/\2/')/pull/new/$branch"
    fi
  fi
  
  return 0
}

# Check PR status and show comments/issues
check_pr_status() {
  local pr_number=$(has_open_pr)
  local branch="$(get_current_branch)"
  
  if [ -z "$pr_number" ]; then
    message 33 "pr" "No open PR found for branch: $branch"
    return 0
  fi
  
  message 34 "pr" "Checking PR #$pr_number status..."
  
  if check_gh_cli; then
    # Get PR details
    local pr_data=$(gh pr view "$pr_number" --json title,url,reviewDecision,reviews,comments)
    
    # Extract key information
    local pr_title=$(echo "$pr_data" | grep -o '"title": "[^"]*' | sed 's/"title": "//')
    local pr_url=$(echo "$pr_data" | grep -o '"url": "[^"]*' | sed 's/"url": "//')
    local review_decision=$(echo "$pr_data" | grep -o '"reviewDecision": "[^"]*' | sed 's/"reviewDecision": "//')
    
    # Count unresolved comments
    local comment_count=$(echo "$pr_data" | grep -o '"body": "[^"]*' | wc -l | tr -d ' ')
    local resolved_count=$(echo "$pr_data" | grep -o '"isResolved": true' | wc -l | tr -d ' ')
    local unresolved_count=$((comment_count - resolved_count))
    
    # Display info
    message 36 "title" "$pr_title"
    message 36 "url" "$pr_url"
    
    # Review status
    case "$review_decision" in
      "APPROVED")
        message 32 "review" "Approved! Ready to merge."
        ;;
      "CHANGES_REQUESTED")
        message 31 "review" "Changes requested. See comments below."
        ;;
      "REVIEW_REQUIRED")
        message 33 "review" "Waiting for review"
        ;;
      *)
        message 33 "review" "No reviews yet"
        ;;
    esac
    
    # Comment status
    if [ "$unresolved_count" -gt 0 ]; then
      message 31 "comments" "$unresolved_count unresolved comments"
      
      # Show unresolved comments
      echo "$pr_data" | grep -A 3 '"isResolved": false' | grep '"body": "' | sed 's/"body": "/- /' | sed 's/\\r\\n/\n/g' | head -5
      
      if [ "$unresolved_count" -gt 5 ]; then
        message 33 "comments" "...and $((unresolved_count - 5)) more comments"
      fi
    else
      message 32 "comments" "No unresolved comments"
    fi
  else
    message 33 "pr" "PR #$pr_number exists, but detailed status check requires GitHub CLI"
    message 33 "pr" "View PR at: https://github.com/$(git remote get-url origin | sed -E 's/.*github.com[:\/](.*)\/(.*)(\.git)?/\1\/\2/')/pull/$pr_number"
  fi
}

cmd_git() {
  subcommand=$1; shift
  case "$subcommand" in
    # Git PR commands
    pr) subcommand=$1; shift; case "$subcommand" in
        create) create_or_update_pr ;;
        check) check_pr_status ;;
        *)
            message 33 "usage" "Usage: $CLI git pr {create|check}"
            echo "  create  - Commit all changes with AI-generated message and create/update PR"
            echo "  check   - Check status of current branch's PR and show unresolved comments"
        ;;
    esac;;
    *)
      message 33 "git" "Available git commands:"
      echo "  pr create - Create/update a PR with AI-generated commit message"
      echo "  pr check  - Check PR status and show unresolved comments"
      ;;
  esac
}
