#!/bin/sh

. $KIT_SRC_DIR/cmds/workspace.sh

set -e

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

# Check if GitHub CLI is installed
check_gh_cli() {
  if ! command -v _gh >/dev/null 2>&1; then
    message 31 "ERROR" "GitHub CLI (gh) is not installed. Please install it first:"
    return 1
  fi
  
  # Check if authenticated
  if ! _gh auth status >/dev/null 2>&1; then
    message 31 "ERROR" "GitHub CLI is not authenticated."
    return 1
  fi
  
  return 0
}

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

# Check if current branch has a PR
has_open_pr() {
  local branch="$CURRENT_BRANCH"
  
  if check_gh_cli; then
    # Try to get PR number for current branch
    pr_number=$(_gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null)
    if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
      echo "$pr_number"
      return 0
    fi
  else
    # Fallback: try to infer from GitHub API via git remote
    local remote_url=$(_git remote get-url origin)
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

cmd_git_pull() {
    cd "$ROOT_DIR"
    ARGS=""; for arg in "$@"; do case "$arg" in
        --ignore-submodule-pulling) IGNORE_SUBMODULE_PULLING="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    message 30 "$CURRENT_BRANCH" "Pulling latest changes .."
    _git -C "$ROOT_DIR" pull origin
    message 30 "$CURRENT_BRANCH" "Merging latest 'main' changes .."
    _git -C "$ROOT_DIR" merge origin/main
    if [ "$IGNORE_SUBMODULE_PULLING" != "true" ]; then
        pull_submodule() {
            local module="$1"
            local module_path="$2"
            (cd "$ROOT_DIR/$module_path" && D pull)
        }
        foreach_selected_module_with_callback pull_submodule
    fi
}

# Commit all changes with AI-generated message and push
commit_and_push() {
  local branch="$CURRENT_BRANCH"
  
  # Don't allow commits directly to main
  if [ "$branch" = "main" ]; then
    message 31 "ERROR" "Cannot commit directly to main branch. Please create a feature branch first."
    return 1
  fi
  
  # Stage all changes
  _git add -A
  
  # Generate commit message
  local commit_msg=$(generate_commit_message)
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  # Commit changes
  message 34 "GIT" "Committing changes with message:"
  message 36 "COMMIT" "$commit_msg"
  echo "$commit_msg" > /tmp/commit-msg.txt
  _git commit -F /tmp/commit-msg.txt
  rm /tmp/commit-msg.txt
  
  # Push to remote
  message 34 "GIT" "Pushing to remote..."
  _git push -u origin "$branch"
  
  return 0
}

# Create a new PR or update existing one
cmd_git_create_or_update_pr() {
  local pr_number=$(has_open_pr)
  local branch="$CURRENT_BRANCH"
  
  # Commit and push changes first
  commit_and_push
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  if [ -n "$pr_number" ]; then
    message 32 "PR" "Updated existing PR #$pr_number"
    
    # If gh CLI is available, provide a link
    if check_gh_cli; then
      local pr_url=$(_gh pr view "$pr_number" --json url -q .url)
      message 36 "URL" "$pr_url"
    fi
  else
    # Create a new PR
    message 34 "PR" "Creating new PR for branch: $branch"
    
    if check_gh_cli; then
      # Use last commit message as PR title/body
      local pr_title=$(_git log -1 --pretty=%s)
      local pr_body=$(_git log -1 --pretty=%b)
      
      if [ -z "$pr_body" ]; then
        pr_body="Changes in this PR:\n\n$(_git diff --stat origin/main..HEAD)"
      fi
      
      # Create PR using GitHub CLI
      local pr_url=$(_gh pr create --title "$pr_title" --body "$pr_body" --base main)
      
      message 32 "PR" "Created new PR:"
      message 36 "URL" "$pr_url"
    else
      message 43 "!" "Install GitHub CLI (gh) for automatic PR creation"
      message 43 "!" "Create PR manually at: https://github.com/$(_git remote get-url origin | sed -E 's/.*github.com[:\/](.*)\/(.*)(\.git)?/\1\/\2/')/pull/new/$branch"
    fi
  fi
  
  return 0
}

# Check PR status and show comments/issues
cmd_git_check_pr_status() {
  if ! "$CLI" internet is-online; then
      message 41 ⊘ "Disconnected, skipping PR status check..."
      return 0
  fi

  local pr_number=$(has_open_pr)
  local branch="$CURRENT_BRANCH"
  
  if [ -z "$pr_number" ]; then
    # message 43 "!" "No open PR found for branch: $branch"
    return 0
  fi
  
  message 34 "pr" "Checking PR #$pr_number status..."
  
  if check_gh_cli; then
    # Get PR details
    local pr_data=$(_gh pr view "$pr_number" --json title,url,reviewDecision,reviews,comments)
    
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
        message 43 "!" "Waiting for review"
        ;;
      *)
        message 43 "!" "No reviews yet"
        ;;
    esac
    
    # Comment status
    if [ "$unresolved_count" -gt 0 ]; then
      message 31 "comments" "$unresolved_count unresolved comments"
      
      # Show unresolved comments
      echo "$pr_data" | grep -A 3 '"isResolved": false' | grep '"body": "' | sed 's/"body": "/- /' | sed 's/\\r\\n/\n/g' | head -5
      
      if [ "$unresolved_count" -gt 5 ]; then
        message 43 "!" "...and $((unresolved_count - 5)) more comments"
      fi
    # else
    #   message 32 "comments" "No unresolved comments"
    fi
  else
    message 43 "!" "PR #$pr_number exists, but detailed status check requires GitHub CLI"
    message 43 "!" "View PR at: https://github.com/$(_git remote get-url origin | sed -E 's/.*github.com[:\/](.*)\/(.*)(\.git)?/\1\/\2/')/pull/$pr_number"
  fi
}

cmd_git_release() {
    local TAG="v$(date +%Y%m%d%H%M%S)"
    # git checkout main
    # git pull origin main
    # git tag -a $TAG -m "Release $TAG"
    # git push origin $TAG
}

