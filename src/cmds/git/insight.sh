#!/bin/bash
# TODO large files for both openai calls like lockfile and auto generated, maybe using a pre call to figure what to inclide and then have a final check to not send request over 1000 tokens (count words?!)
# TODO cache the resutl and make sure is created only once a day
# TODO extrac the openai call functionalities

. $KIT_SRC_DIR/cmds/secret/index.sh

cmd_git_head() {
  if check_gh_cli; then
    local pr_link=$(_gh pr view "$(has_open_pr)" --json url -q .url)
  fi
  local commit_link="https://github.com/$ORG_NAME/$REPO_NAME/commit/$(_git rev-parse HEAD)"

  # Commit changes
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


cmd_git_daily_insight() {
    # Validate OpenAI API key
    if validate_and_prepare_secret "OPENAI_API_KEY"; then
        local OPENAI_API_KEY="$(cmd_secret_export OPENAI_API_KEY)"
    else
        message 31 "ERROR" "Unable to prepare secret 'OPENAI_API_KEY' for export" >&2
        return 1
    fi

    # Get today's date range (00:00 to now)
    local today_start=$(date '+%Y-%m-%d 00:00:00')
    local today_end=$(date '+%Y-%m-%d %H:%M:%S')
    
    message 34 "INFO" "Generating daily insight report for $today_start to $today_end"
    
    # Collect all commits and changes data
    local all_commits=""
    local all_changes=""
    local total_files_changed=0
    local total_insertions=0
    local total_deletions=0
    
    # Function to collect commit data for a repository
    collect_repo_data() {
        local module_name="$1"
        local module_path="$2"
        local repo_path="$ROOT_DIR/$module_path"
        
        if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
            return 0
        fi
        
        # Get today's commits
        local commits=$(cd "$repo_path" && _git log --since="$today_start" --until="$today_end" --pretty=format:"%h|%s|%an|%ad" --date=short 2>/dev/null)
        
        if [ -n "$commits" ]; then
            while IFS='|' read -r hash subject author date; do
                if [ -n "$hash" ]; then
                    # Get detailed diff for this commit
                    local commit_diff=$(cd "$repo_path" && _git show --stat "$hash" 2>/dev/null)
                    all_commits="$all_commits
REPO: $module_name
COMMIT: $hash - $subject
AUTHOR: $author
DATE: $date
CHANGES:
$commit_diff
---"
                fi
            done <<< "$commits"
        fi
        
        # Get uncommitted changes
        local status_output=$(cd "$repo_path" && _git status --porcelain 2>/dev/null)
        if [ -n "$status_output" ]; then
            local unstaged_diff=$(cd "$repo_path" && _git diff 2>/dev/null)
            local staged_diff=$(cd "$repo_path" && _git diff --staged 2>/dev/null)
            
            if [ -n "$unstaged_diff" ] || [ -n "$staged_diff" ]; then
                all_changes="$all_changes
REPO: $module_name - UNCOMMITTED CHANGES
STATUS:
$status_output"
                
                if [ -n "$staged_diff" ]; then
                    all_changes="$all_changes
STAGED CHANGES:
$staged_diff"
                fi
                
                if [ -n "$unstaged_diff" ]; then
                    all_changes="$all_changes
UNSTAGED CHANGES:
$unstaged_diff"
                fi
                
                all_changes="$all_changes
---"
            fi
        fi
        
        # Calculate stats
        local repo_stats=$(cd "$repo_path" && _git log --since="$today_start" --until="$today_end" --numstat 2>/dev/null)
        if [ -n "$repo_stats" ]; then
            while read -r insertions deletions file; do
                if [ "$insertions" != "-" ] && [ "$deletions" != "-" ]; then
                    total_insertions=$((total_insertions + insertions))
                    total_deletions=$((total_deletions + deletions))
                    total_files_changed=$((total_files_changed + 1))
                fi
            done <<< "$repo_stats"
        fi
    }
    
    # Process main repository
    collect_repo_data "$REPO_NAME" "."
    
    # Process all selected submodules
    foreach_selected_module_with_callback collect_repo_data
    
    # If no data collected, show simple message
    if [ -z "$all_commits" ] && [ -z "$all_changes" ]; then
        message 33 "INFO" "No commits or changes found for today"
        return 0
    fi
    
    # Prepare data for AI analysis
    local analysis_data="Daily Development Report - $(date '+%Y-%m-%d')

Repository: $REPO_NAME
Developer: $(_git config user.name)
Email: $(_git config user.email)
Branch: $CURRENT_BRANCH

=== COMMITS TODAY ===
$all_commits

=== UNCOMMITTED CHANGES ===
$all_changes

=== SUMMARY STATS ===
Files changed: $total_files_changed
Lines added: +$total_insertions
Lines removed: -$total_deletions
"
    
    # Generate AI summary
    message 34 "INFO" "Analyzing changes with AI..."
    
    local prompt="Analyze the following development activity and create a concise daily insight report.

$analysis_data

Please format the response as:
1. A single descriptive title
2. A bulleted list of key deliverables and values added (focus on CRITICAL to MEDIUM level changes)
3. Each bullet should start with '-' and mention specific files/repositories when relevant
4. Focus on: new features, bug fixes, refactoring, performance improvements, security enhancements
5. Keep descriptions brief but informative
6. No empty lines between bullets
7. End with a summary line showing total changes

Example format:
Enhanced Authentication and Performance Optimizations
- Fixed critical authentication bug X in user-service/auth.js affecting login flow
- Added new user dashboard feature X in frontend/components/Dashboard.tsx
- Refactored database connection pooling in api/database.js for 40% performance improvement
- Updated security headers configuration in nginx.conf
- Optimized API response caching in services/cache-service

Total: 15 files changed (+234 -67 lines)"
    
    # Escape the prompt for JSON
    local escaped_prompt=$(echo "$prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' '\r' | sed 's/\r/\\n/g')
    
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\": \"gpt-4\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}], \"temperature\": 0.3}")
    
    # Check if the response contains an error
    if echo "$response" | grep -q '"error"'; then
        message 31 "ERROR" "OpenAI API error. Showing raw data instead."
        echo ""
        echo "$analysis_data"
        return 1
    fi
    
    # Extract and display the AI-generated insight
    local ai_insight=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$response" | grep -o '"content":"[^"]*"' | sed 's/"content":"//g' | sed 's/"$//g' | sed 's/\\n/\n/g')
    
    if [ -n "$ai_insight" ]; then
        echo ""
        echo "$ai_insight"
        echo ""
        
        # Show final diff summary
        if [ $total_files_changed -gt 0 ]; then
            message 36 "SUMMARY" "Total changes: $total_files_changed files (+$total_insertions -$total_deletions lines)"
        fi
    else
        message 31 "ERROR" "Failed to generate AI insight. Showing raw data."
        echo ""
        echo "$analysis_data"
    fi
    
    echo ""
}

