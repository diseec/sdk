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
