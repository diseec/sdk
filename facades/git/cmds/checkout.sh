#!/bin/bash

sdk_fac_git_cmd_checkout_branch() {
    local mode="$1" # options: --skip-check

    # Check for uncommitted changes
    local uncommitted_changes=$(_git status --porcelain)
    if [ -n "$uncommitted_changes" ]; then
        stdout -w "You have uncommitted changes, please commit or stash them before switching branches."
    fi

    # Check for unpushed commits
    local unpushed_commits=$(_git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed_commits" -gt 0 ]; then
        stdout -w "You have $unpushed_commits unpushed commits. Please push them before switching branches."
    fi

    # if has uncommitted changes or unpushed commits and not in skip-check mode, prompt user
    if [ "$mode" != "--skip-check" ]; then
        if [ "$unpushed_commits" -gt 0 ] || [ -n "$uncommitted_changes" ]; then
            if confirm "Commit-push-pr (cpp) now?"; then
                cli_ctx git commit-push-pr
            elif ! confirm "Proceeding may result in work loss, continue anyway?"; then
                return 1
            fi
        fi
    fi

    GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
    stdin BRANCH "Branch to checkout:" --default="$GH_USERNAME"
    if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi

    stdout -l --processing "Checking out to branch '$BRANCH'"
    _git fetch && _git checkout $BRANCH || _git checkout -b $BRANCH origin/$BRANCH || _git checkout -b $BRANCH;
}

sdk_fac_git_cmd_checkout_if_detached() {
    if _git symbolic-ref HEAD >/dev/null 2>&1; then
        # stdout -l "Already on a branch, no checkout needed."
        return 0
    else
        stdout -w "$D_REPO_NAME: Repository is in detached HEAD state."
        # Check for local changes in detached HEAD
        if [ -n "$(_git status --porcelain)" ]; then
            stdout -e "You have local changes in detached HEAD."
            # Prompt for branch to merge changes into
            GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
            stdin TARGET_BRANCH "Branch to merge changes into:" --default="$GH_USERNAME"
            if [ -z "$TARGET_BRANCH" ]; then TARGET_BRANCH="$GH_USERNAME"; fi
            TEMP_BRANCH="temp-detached-$(date +%s)"
            stdout -l --processing "Creating temporary branch '$TEMP_BRANCH' from detached HEAD"
            _git checkout -b "$TEMP_BRANCH"
            stdout -l --processing "Committing local changes on '$TEMP_BRANCH'"
            _git add . && _git commit -m "WIP: changes from detached HEAD" || true
            stdout -l --processing "Checking out to target branch '$TARGET_BRANCH'"
            _git fetch && _git checkout "$TARGET_BRANCH" || _git checkout -b "$TARGET_BRANCH" origin/"$TARGET_BRANCH" || _git checkout -b "$TARGET_BRANCH"
            stdout -l --processing "Merging changes from '$TEMP_BRANCH' into '$TARGET_BRANCH'"
            _git merge "$TEMP_BRANCH"
            stdout -l --processing "Deleting temporary branch '$TEMP_BRANCH'"
            _git branch -d "$TEMP_BRANCH"
        else
            sdk_fac_git_cmd_checkout_branch
            # After branch checkout, check for uncommitted changes left behind
            if [ -n "$(_git status --porcelain)" ]; then
                stdout -e "You have uncommitted changes that may have been left behind after switching from detached HEAD."
                echo "$(ansi 35 "[1]") $(ansi 97 "Stash them")"
                echo "$(ansi 35 "[2]") $(ansi 97 "Commit to a temporary branch")"
                echo "$(ansi 35 "[3]") $(ansi 97 "Merge into current branch")"
                stdin DANGER_CHOICE "Choose how to handle these changes [1/2/3]:"
                case "$DANGER_CHOICE" in
                    1)
                        _git stash
                        stdout -l "Changes stashed."
                        ;;
                    2)
                        TEMP_BRANCH="temp-uncommitted-$(date +%s)"
                        _git checkout -b "$TEMP_BRANCH"
                        _git add . && _git commit -m "WIP: uncommitted changes after detached HEAD" || true
                        stdout -l "Changes committed to temporary branch '$TEMP_BRANCH'."
                        ;;
                    3)
                        _git add . && _git commit -m "WIP: merge uncommitted changes after detached HEAD" || true
                        stdout -l "Changes committed to current branch."
                        ;;
                    *)
                        stdout -l "No action taken. Please handle changes manually."
                        ;;
                esac
            fi
        fi
    fi
}
