#!/bin/bash

# Generic function to display commit information for any commit ID
sdk_fac_git_cmd_git_log() {
    local commit_id="${1:-HEAD}"
    
    # Validate commit exists
    if ! _git rev-parse --verify "$commit_id" >/dev/null 2>&1; then
        echo "Error: Commit '$commit_id' not found"
        return 1
    fi
    
    # Get commit hash (resolve to full hash)
    local commit_hash=$(_git rev-parse "$commit_id")
    local commit_link="https://github.com/$D_ORG_NAME/$D_REPO_NAME/commit/$commit_hash"
    
    # Get PR link only if requested and we're checking HEAD
    local pr_link=$(_gh pr view "$(sdk_fac_git_cmd_has_open_pr)" --json url -q .url)
    
    # Get commit info
    local commit_date=$(_git log -1 --pretty=%cd --date=iso "$commit_id")
    local commit_author=$(_git log -1 --pretty=%an "$commit_id")
    local commit_email=$(_git log -1 --pretty=%ae "$commit_id")
    local commit_message=$(_git log -1 --pretty=%B "$commit_id")
    
    # Get branch info (current branch if HEAD, otherwise try to find branch)
    local branch_info="$D_CURRENT_BRANCH"
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
    echo -e " \033[97mDate         $commit_date\033[0m"
    echo -e " \033[97mDeveloper    $commit_author\033[0m"
    echo -e " \033[97mEmail        $commit_email\033[0m"
    echo -e " \033[97mRepo         $D_REPO_NAME\033[0m"
    echo -e " \033[97mBranch       $branch_info\033[0m"
    echo -e " \033[97mCommit       \033[4m$commit_link\033[24m\033[0m"
    if [ -n "$pr_link" ]; then
        echo -e " \033[97mPR           \033[4m$pr_link\033[24m\033[0m"
    fi
    echo ""
    echo -e "\033[97m--------------------\033[0m"
    echo ""
    echo -e " \033[97m$commit_message\033[0m"
    echo ""
    echo -e "\033[97m--------------------\033[0m"
    echo ""
    # Show diff stats against previous commit
    echo -e "\033[97m$(_git diff "$commit_id~1" "$commit_id" --stat 2>/dev/null || echo "No previous commit to compare")\033[0m"
    echo ""
}

# sdk_fac_git_cmd_daily_insight() {
#     # Get today's date range (00:00 to now)
#     local today_start=$(date '+%Y-%m-%d 00:00:00')
#     local today_end=$(date '+%Y-%m-%d %H:%M:%S')
#     local today_date=$(date '+%Y-%m-%d')
#     local cache_dir=$(cli_ctx config function sdk_fac_con_get_cache_subdir "repository" "insights")
#     local cache_file="$cache_dir/daily_insight_$today_date.txt"

#     # Check if cache exists for today
#     if [ -f "$cache_file" ]; then
#         read -p "Found insight for today $today_date. rewrite? [Y/N]: " cache_choice
#         if [[ "$cache_choice" =~ ^[Yy]$ ]]; then
#             echo "Rewriting daily insight report..."
#             # Continue to generate a new report
#         else
#             echo ""
#             echo -e "\033[36m$(cat "$cache_file")\033[0m"
#             echo ""
#             return 0
#         fi
#     fi
    
#     echo "Preparing daily insight report for $today_start to $today_end.."
    
#     # Collect all commits and changes data
#     local all_commits=""
#     local all_changes=""
#     local total_files_changed=0
#     local total_insertions=0
#     local total_deletions=0
#     local commit_list=""
    
#     # Function to collect commit data for a repository
#     collect_repo_data() {
#         local module_name="$1"
#         local module_path="$2"
#         local repo_path="$D_CTX_DIR/$module_path"
        
#         if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
#             return 0
#         fi
        
#         # Get today's commits - use proper git execution within the submodule context
#         local commits=""
#         if [ "$module_path" = "." ]; then
#             # For main repository
#             commits=$(cd "$repo_path" && sdk_fac_git_cmd_get_today_logs)
#         else
#             # For submodules - directly use git in the submodule directory
#             commits=$(cd "$repo_path" && $D_CLI_GLOBAL_NAME api v1 git.log.--today)
#         fi
        
#         if [ -n "$commits" ]; then
#             while IFS='|' read -r hash subject author date; do
#                 if [ -n "$hash" ]; then
#                     # Save to commit list for later display - clean format for table display
#                     commit_list+="$module_name: $hash - $subject ($author, $date)"$'\n'
                    
#                     # Get detailed diff for this commit - using quotes around hash to avoid arithmetic interpretation
#                     local commit_diff=""
#                     if [ "$module_path" = "." ]; then
#                         # For main repository
#                         commit_diff=$(cd "$repo_path" && _git show --stat "$hash" 2>/dev/null)
#                     else
#                         # For submodules - directly use git in the submodule directory
#                         commit_diff=$(cd "$repo_path" && git show --stat "$hash" 2>/dev/null)
#                     fi
                    
#                     # Check for large auto-generated files and exclude them
#                     local cleaned_diff=""
#                     local file_lines=$(echo "$commit_diff" | grep '|' | sed 's/|.*$//' | sed 's/^ *//')
                    
#                     # Check if any files in the diff might be large auto-generated files
#                     local has_large_files=false
#                     while IFS= read -r file; do
#                         if [ -n "$file" ] && [ -f "$repo_path/$file" ] && cli_ctx ai function sdk_fac_ai_is_large_autogenerated_file "$repo_path/$file"; then
#                             has_large_files=true
#                             # Use grep -F for fixed string matching to avoid regex interpretation of hash
#                             commit_diff=$(echo "$commit_diff" | grep -F -v "$file")
#                         fi
#                     done <<< "$file_lines"
                    
#                     if [ "$has_large_files" = true ]; then
#                         commit_diff+=$'\n[Some large or auto-generated files were excluded]'
#                     fi
                    
#                     all_commits="$all_commits
# REPO: $module_name
# COMMIT: \"$hash\" - $subject
# AUTHOR: $author
# DATE: $date
# CHANGES:
# $commit_diff
# ---"
#                 fi
#             done <<< "$commits"
#         fi
        
#         # Get uncommitted changes
#         local status_output=""
#         if [ "$module_path" = "." ]; then
#             # For main repository
#             status_output=$(cd "$repo_path" && _git status --porcelain 2>/dev/null)
#         else
#             # For submodules - directly use git in the submodule directory
#             status_output=$(cd "$repo_path" && git status --porcelain 2>/dev/null)
#         fi
        
#         if [ -n "$status_output" ]; then
#             # Filter out large auto-generated files from status
#             local filtered_status=""
#             while IFS= read -r line; do
#                 local file=$(echo "$line" | sed 's/^...//')
#                 if [ -n "$file" ] && [ -f "$repo_path/$file" ] && ! cli_ctx ai function sdk_fac_ai_is_large_autogenerated_file "$repo_path/$file"; then
#                     filtered_status+="$line"$'\n'
#                 fi
#             done <<< "$status_output"
            
#             local unstaged_diff=""
#             local staged_diff=""
#             if [ "$module_path" = "." ]; then
#                 # For main repository
#                 unstaged_diff=$(cd "$repo_path" && _git diff 2>/dev/null)
#                 staged_diff=$(cd "$repo_path" && _git diff --staged 2>/dev/null)
#             else
#                 # For submodules - directly use git in the submodule directory
#                 unstaged_diff=$(cd "$repo_path" && git diff 2>/dev/null)
#                 staged_diff=$(cd "$repo_path" && git diff --staged 2>/dev/null)
#             fi
            
#             if [ -n "$unstaged_diff" ] || [ -n "$staged_diff" ]; then
#                 all_changes="$all_changes
# REPO: $module_name - UNCOMMITTED CHANGES
# STATUS:
# $filtered_status"
                
#                 if [ -n "$staged_diff" ]; then
#                     all_changes="$all_changes
# STAGED CHANGES:
# $staged_diff"
#                 fi
                
#                 if [ -n "$unstaged_diff" ]; then
#                     all_changes="$all_changes
# UNSTAGED CHANGES:
# $unstaged_diff"
#                 fi
                
#                 all_changes="$all_changes
# ---"
#             fi
#         fi
        
#         # Calculate stats
#         local repo_stats=""
#         if [ "$module_path" = "." ]; then
#             # For main repository
#             repo_stats=$(cd "$repo_path" && _git log --since="$today_start" --until="$today_end" --numstat 2>/dev/null)
#         else
#             # For submodules - directly use git in the submodule directory
#             repo_stats=$(cd "$repo_path" && git log --since="$today_start" --until="$today_end" --numstat 2>/dev/null)
#         fi
        
#         if [ -n "$repo_stats" ]; then
#             while read -r insertions deletions file; do
#                 # Make sure insertions and deletions are treated as numbers
#                 if [[ "$insertions" =~ ^[0-9]+$ ]] && [[ "$deletions" =~ ^[0-9]+$ ]]; then
#                     total_insertions=$((total_insertions + insertions))
#                     total_deletions=$((total_deletions + deletions))
#                     total_files_changed=$((total_files_changed + 1))
#                 fi
#             done <<< "$repo_stats"
#         fi
#     }
    
#     # Process main repository
#     collect_repo_data "$D_REPO_NAME" "."
    
#     # Process all selected submodules
#     cli_ctx config function sdk_fac_con_opt_act_foreach_selected_module collect_repo_data
    
#     # If no data collected, show simple message
#     if [ -z "$all_commits" ] && [ -z "$all_changes" ]; then
#         logit -i "No commits or changes found for today"
#         return 0
#     fi
    
#     # Prompt user to confirm before generating the report
#     echo "The following commits will be included in the daily insight:"
    
#     echo ""
#     # Format and display commit list as a table
#     # Column headers
#     printf "%-15s %-8s %-50s %-20s %-10s\n" "REPOSITORY" "COMMIT" "MESSAGE" "AUTHOR" "DATE"
#     printf "%s\n" "$(printf '=%.0s' {1..110})"
    
#     # Process commit list and format as a table
#     echo "$commit_list" | while IFS= read -r line; do
#         if [ -n "$line" ]; then
#             # Parse the line with a more reliable approach
#             repo=$(echo "$line" | cut -d: -f1)
#             rest=$(echo "$line" | cut -d: -f2- | sed 's/^ //')
            
#             hash=$(echo "$rest" | awk '{print $1}')
            
#             # Extract the commit message more robustly
#             message=$(echo "$rest" | sed -E 's/^[^ ]+ - (.+) \([^,]+, [0-9-]+\)$/\1/')
            
#             # Truncate message if too long
#             if [ ${#message} -gt 47 ]; then
#                 message="${message:0:44}..."
#             fi
            
#             # Extract author and date
#             author=$(echo "$rest" | sed -E 's/^.+\(([^,]+), ([0-9-]+)\)$/\1/')
#             date=$(echo "$rest" | sed -E 's/^.+\(([^,]+), ([0-9-]+)\)$/\2/')
            
#             printf "%-15s %-8s %-50s %-20s %-10s\n" "$repo" "$hash" "$message" "$author" "$date"
#         fi
#     done
    
#     echo ""
#     echo "Total changes: $total_files_changed files (+$total_insertions -$total_deletions lines)"
#     echo ""
    
#     read -p "Generate daily insight report? (y/n): " confirm
#     if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
#         logit -w "Daily insight report generation cancelled"
#         return 0
#     fi
    
#     # Prepare data for AI analysis
#     local analysis_data="
# === COMMITS TODAY ===
# $all_commits

# === UNCOMMITTED CHANGES ===
# $all_changes
# "

#     # Use AI to generate insight report
#     if cli_ctx ai function sdk_fac_ai_is_available; then
#         echo ""
#         logit -a "Writing daily insights..."
#         echo ""

#         local ai_insight=$(cli_ctx ai function sdk_fac_ai_generate_daily_insight "$analysis_data")
        
#         if [ -n "$ai_insight" ]; then
#             # Cache directory is already created by cli_ctx config function sdk_fac_con_get_cache_subdir repository
            
#             # Save the result to cache
#             {
#                 echo "Daily Development Report - $(date '+%Y-%m-%d')"
#                 echo ""
#                 echo "$ai_insight"
#                 echo ""
#                 echo "$total_files_changed files changes (+$total_insertions -$total_deletions lines)"
#             } > "$cache_file"
            
#             echo "Daily insight report generated and cached"
#             echo ""
#             echo -e "\033[36m$(cat "$cache_file")\033[0m"
            
#             # Show final diff summary
#             # if [ $total_files_changed -gt 0 ]; then
#             #     echo "Total changes: $total_files_changed files (+$total_insertions -$total_deletions lines)"
#             # fi
#         else
#             logit -e "Failed to generate AI insight. Showing raw data."
#             echo ""
#             echo "$analysis_data"
#         fi
#     else
#         logit -e "AI not available. Showing raw data instead."
#         echo ""
#         echo "$analysis_data"
#     fi
#     echo ""
# }

