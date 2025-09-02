#!/bin/bash

fac_git_cmd_checkout_branch() {
    echo "$REPO_NAME: Setting up branch tracking..."

    # Check for uncommitted changes
    if [ -n "$(_git status --porcelain)" ]; then
        logit -e "You have uncommitted changes. Please commit or stash them before switching branches."
        return 1
    fi

    # Check for unpushed commits
    local unpushed_commits=$(_git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed_commits" -gt 0 ]; then
        logit -e "You have $unpushed_commits unpushed commits. Please push them before switching branches."
        return 1
    fi

    GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
    read -p "$(logit --ansi="35" --icon="?" "Branch to checkout: (press enter for '$GH_USERNAME')") " BRANCH
    if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi

    echo "$REPO_NAME: Checking out to branch '$BRANCH'..."
    _git fetch && _git checkout $BRANCH || _git checkout -b $BRANCH origin/$BRANCH || _git checkout -b $BRANCH;
}

fac_git_cmd_checkout_if_detached() {
    if _git symbolic-ref HEAD >/dev/null 2>&1; then
        # echo "$REPO_NAME: Already on a branch, no checkout needed."
        return 0
    else
        logit -w "$REPO_NAME: Repository is in detached HEAD state."
        # Check for local changes in detached HEAD
        if [ -n "$(_git status --porcelain)" ]; then
            logit -e "You have local changes in detached HEAD."
            # Prompt for branch to merge changes into
            GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
            read -p "$(logit --ansi="35" --icon="?" "Branch to merge changes into: (press enter for '$GH_USERNAME')") " TARGET_BRANCH
            if [ -z "$TARGET_BRANCH" ]; then TARGET_BRANCH="$GH_USERNAME"; fi
            TEMP_BRANCH="temp-detached-$(date +%s)"
            echo "$REPO_NAME: Creating temporary branch '$TEMP_BRANCH' from detached HEAD..."
            _git checkout -b "$TEMP_BRANCH"
            echo "$REPO_NAME: Committing local changes on '$TEMP_BRANCH'..."
            _git add . && _git commit -m "WIP: changes from detached HEAD" || true
            echo "$REPO_NAME: Checking out to target branch '$TARGET_BRANCH'..."
            _git fetch && _git checkout "$TARGET_BRANCH" || _git checkout -b "$TARGET_BRANCH" origin/"$TARGET_BRANCH" || _git checkout -b "$TARGET_BRANCH"
            echo "$REPO_NAME: Merging changes from '$TEMP_BRANCH' into '$TARGET_BRANCH'..."
            _git merge "$TEMP_BRANCH"
            echo "$REPO_NAME: Deleting temporary branch '$TEMP_BRANCH'..."
            _git branch -d "$TEMP_BRANCH"
        else
            fac_git_cmd_checkout_branch
            # After branch checkout, check for uncommitted changes left behind
            if [ -n "$(_git status --porcelain)" ]; then
                logit -e "You have uncommitted changes that may have been left behind after switching from detached HEAD."
                echo "$REPO_NAME: Choose how to handle these changes:"
                echo "1) Stash them"
                echo "2) Commit to a temporary branch"
                echo "3) Merge into current branch"
                read -p "Enter choice [1/2/3]: " DANGER_CHOICE
                case "$DANGER_CHOICE" in
                    1)
                        _git stash
                        echo "$REPO_NAME: Changes stashed."
                        ;;
                    2)
                        TEMP_BRANCH="temp-uncommitted-$(date +%s)"
                        _git checkout -b "$TEMP_BRANCH"
                        _git add . && _git commit -m "WIP: uncommitted changes after detached HEAD" || true
                        echo "$REPO_NAME: Changes committed to temporary branch '$TEMP_BRANCH'."
                        ;;
                    3)
                        _git add . && _git commit -m "WIP: merge uncommitted changes after detached HEAD" || true
                        echo "$REPO_NAME: Changes committed to current branch."
                        ;;
                    *)
                        echo "$REPO_NAME: No action taken. Please handle changes manually."
                        ;;
                esac
            fi
        fi
    fi
}
