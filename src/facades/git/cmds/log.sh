#!/bin/bash
# TODO large files for both openai calls like lockfile and auto generated, maybe using a pre call to figure what to inclide and then have a final check to not send request over 1000 tokens (count words?!)
# TODO cache the resutl and make sure is created only once a day
# TODO extrac the openai call functionalities

. $KIT_SRC_DIR/utils/ai/index.sh

# Generic function to display commit information for any commit ID
cmd_git_log() {
    local commit_id="${1:-HEAD}"
    
    # Validate commit exists
    if ! _git rev-parse --verify "$commit_id" >/dev/null 2>&1; then
        echo "Error: Commit '$commit_id' not found"
        return 1
    fi
    
    # Get commit hash (resolve to full hash)
    local commit_hash=$(_git rev-parse "$commit_id")
    local commit_link="https://github.com/$ORG_NAME/$REPO_NAME/commit/$commit_hash"
    
    # Get PR link only if requested and we're checking HEAD
    local pr_link=$(_gh pr view "$(has_open_pr)" --json url -q .url)
    
    # Get commit info
    local commit_date=$(_git log -1 --pretty=%cd --date=iso "$commit_id")
    local commit_author=$(_git log -1 --pretty=%an "$commit_id")
    local commit_email=$(_git log -1 --pretty=%ae "$commit_id")
    local commit_message=$(_git log -1 --pretty=%B "$commit_id")
    
    # Get branch info (current branch if HEAD, otherwise try to find branch)
    local branch_info="$CURRENT_BRANCH"
    if [ "$commit_id" != "HEAD" ]; then
        local branches=$(_git branch --contains "$commit_id" 2>/dev/null | grep -v '^\*' | head -1 | sed 's/^[ ]*//')
        if [ -n "$branches" ]; then
        branch_info="$branches"
        else
        branch_info="(detached)"
        fi
    fi
    
    # Display commit information
    echo ""
    echo -e " \033[30mDATE $commit_date\033[0m"
    echo -e " \033[30mDEVE $commit_author\033[0m"
    echo -e " \033[30mEMAI $commit_email\033[0m"
    echo -e " \033[30mREPO $REPO_NAME\033[0m"
    echo -e " \033[30mBRAN $branch_info\033[0m"
    echo -e " \033[30mCOMM \033[4m$commit_link\033[24m\033[0m"
    if [ -n "$pr_link" ]; then
        echo -e " \033[30mPULL \033[4m$pr_link\033[24m\033[0m"
    fi
    echo ""
    echo -e "\033[30m--------------------\033[0m"
    echo ""
    echo -e " \033[30m$commit_message\033[0m"
    echo ""
    echo -e "\033[30m--------------------\033[0m"
    echo ""
    # Show diff stats against previous commit
    echo -e "\033[30m$(_git diff "$commit_id~1" "$commit_id" --stat 2>/dev/null || echo "No previous commit to compare")\033[0m"
    echo ""
}

cmd_git_daily_insight() {
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
    
    echo 'asfhd'
    exit 0
    
    # Use AI to generate insight report
    if ai_is_available; then
        local ai_insight=$(ai_generate_daily_insight "$analysis_data")
        
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
    else
        message 31 "ERROR" "AI not available. Showing raw data instead."
        echo ""
        echo "$analysis_data"
    fi
    
    echo ""
}

