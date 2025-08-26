#!/bin/bash

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

# Create a new PR or update existing one
cmd_git_pr_create() {
    local pr_number=$(has_open_pr)
    local branch="$CURRENT_BRANCH"

    if [ "$CURRENT_BRANCH" = "main" ]; then
        message 41 "!" "Creating a PR from the main branch is not allowed."
        return 1
    fi

    if [ -n "$pr_number" ]; then
        echo -e "Pull request already open: \033[4m$(_gh pr view "$pr_number" --json url -q .url)\033[24m"
    else
    # Create a new PR
    echo "Creating new PR for branch: $branch"
    if check_gh_cli; then
      # Use last commit message as PR title/body
      local pr_title=$(_git log -1 --pretty=%s)
      local pr_body=$(_git log -1 --pretty=%b)
      
      if [ -z "$pr_body" ]; then
        pr_body="Changes in this PR:\n\n$(_git diff --stat origin/main..HEAD)"
      fi
      
      # Create PR using GitHub CLI
      local pr_url=$(_gh pr create --title "$pr_title" --body "$pr_body" --base main)
      if [ $? -ne 0 ]; then
        message 41 "ERROR" "Failed to create PR."
        return 1
      fi
      echo -e "Created pull request: \033[4m$pr_url\033[24m"
    else
      message 41 "!" "Install GitHub CLI (gh) for automatic PR creation"
      echo -e "Create PR manually at: \033[4mhttps://github.com/$ORG_NAME/$REPO_NAME/pull/new/$branch\033[24m"
      return 1
    fi
  fi
  
  # Provide links
  if check_gh_cli; then
    local pr_link=$(_gh pr view "$(has_open_pr)" --json url -q .url)
  fi
  local commit_link="https://github.com/$ORG_NAME/$REPO_NAME/commit/$(_git rev-parse HEAD)"

  return 0
}

# Check PR status and show comments/issues
cmd_git_pr_check_status() {
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
    message 43 "!" "View PR at: \033[4mhttps://github.com/$(_git remote get-url origin | sed -E 's/.*github.com[:\/](.*)\/(.*)(\.git)?/\1\/\2/')/pull/$pr_number\033[24m"
  fi
}
