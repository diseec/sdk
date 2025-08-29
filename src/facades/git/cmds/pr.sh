#!/bin/bash

# Check if current branch has a PR
fac_git_cmd_has_open_pr() {
  set -e
  local branch="$CURRENT_BRANCH"
  
  if fac_git_cmd_check_gh_cli; then
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
fac_git_cmd_pr_create() {
    local pr_number=$(fac_git_cmd_has_open_pr)
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
    if fac_git_cmd_check_gh_cli; then
      # Use last commit message as PR title/body
      local pr_title=$(_git log -1 --pretty=%s)
      local pr_body=$(_git log -1 --pretty=%b)
      
      if [ -z "$pr_body" ]; then
        pr_body="Changes in this PR:\n\n$(_git diff --stat origin/main..HEAD)"
      fi
      
      # Create PR using GitHub cli_main
      local pr_url=$(_gh pr create --title "$pr_title" --body "$pr_body" --base main)
      if [ $? -ne 0 ]; then
        message 41 "!" "Failed to create PR."
        return 1
      fi
      echo -e "Created pull request: \033[4m$pr_url\033[24m"
    else
      message 41 "!" "Install GitHub cli_main (gh) for automatic PR creation"
      echo -e "Create PR manually at: \033[4mhttps://github.com/$ORG_NAME/$REPO_NAME/pull/new/$branch\033[24m"
      return 1
    fi
  fi
  
  # Provide links
  if fac_git_cmd_check_gh_cli; then
    local pr_link=$(_gh pr view "$(fac_git_cmd_has_open_pr)" --json url -q .url)
  fi
  local commit_link="https://github.com/$ORG_NAME/$REPO_NAME/commit/$(_git rev-parse HEAD)"

  return 0
}

# Check PR status and show comments/issues
fac_git_cmd_pr_check_status() {
  if ! cli_main internet is-online; then
      message 41 ⊘ "Disconnected, skipping PR status check..."
      return 0
  fi
  echo "Checking PR status..."

  local pr_number=$(fac_git_cmd_has_open_pr)
  local branch="$CURRENT_BRANCH"

  if [ -z "$pr_number" ]; then
      # message 43 "!" "No open PR found for branch: $branch"
      return 0
  fi

  # echo "Checking PR #$pr_number status..."

  if fac_git_cmd_check_gh_cli; then
      # Get PR details
      local pr_data=$(_gh pr view "$pr_number" --json title,url,reviewDecision,reviews,comments)

      # Ensure jq is available for reliable JSON parsing
      if ! command -v jq >/dev/null 2>&1; then
          message 43 "!" "jq is required for JSON parsing. Please install jq and try again."
          return 0
      fi

      # Extract key information using jq
      local pr_title=$(echo "$pr_data" | _jq -r '.title // ""')
      local pr_url=$(echo "$pr_data" | _jq -r '.url // ""')
      local review_decision=$(echo "$pr_data" | _jq -r '.reviewDecision // ""')

      # Count comments and unresolved comments reliably with jq
      local comment_count=$(echo "$pr_data" | _jq -r '.comments // [] | length')
      local resolved_count=$(echo "$pr_data" | _jq -r '[.comments[]? | select(.isResolved == true)] | length')
      local unresolved_count=$(echo "$pr_data" | _jq -r '[.comments[]? | select(.isResolved != true)] | length')
      
      # Display info
      message 34 "PR#$pr_number" "title: $pr_title"
      message 34 "PR#$pr_number" "url: $pr_url"
      
      # Review status
      case "$review_decision" in
          "APPROVED") message 42 "✔" "Approved! Ready to merge." ;;
          "CHANGES_REQUESTED") message 41 "⊝" "Changes requested. See comments below." ;;
          "REVIEW_REQUIRED") message 43 "⊙" "Waiting for review" ;;
          *) message "No reviews yet" ;;
      esac
    
    # Comment status
      if [ "$unresolved_count" -gt 0 ]; then
          message 31 "comments" "$unresolved_count unresolved comments"
          
          # Show unresolved comments
          echo "$pr_data" | grep -A 3 '"isResolved": false' | grep '"body": "' | sed 's/"body": "/- /' | sed 's/\\r\\n/\n/g' | head -5
          
          if [ "$unresolved_count" -gt 5 ]; then
              message 43 "⚭" "...and $((unresolved_count - 5)) more comments"
          fi
      # else
      #   message 32 "comments" "No unresolved comments"
      fi
  else
      message 41 "!" "PR #$pr_number exists, but detailed status check requires GitHub CLI"
      message 41 "!" "View PR at: \033[4mhttps://github.com/$(_git remote get-url origin | sed -E 's/.*github.com[:\/](.*)\/(.*)(\.git)?/\1\/\2/')/pull/$pr_number\033[24m"
  fi
}
