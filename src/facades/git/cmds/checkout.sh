#!/bin/bash

cmd_git_checkout_branch() {
    echo "$REPO_NAME: Setting up branch tracking..."

    # Check for uncommitted changes
    if [ -n "$(_git status --porcelain)" ]; then
        message 41 "!" "You have uncommitted changes. Please commit or stash them before switching branches."
        return 1
    fi

    # Check for unpushed commits
    local unpushed_commits=$(_git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed_commits" -gt 0 ]; then
        message 41 "!" "You have $unpushed_commits unpushed commits. Please push them before switching branches."
        return 1
    fi

    GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
    read -p "$(message 45 "?" "Branch to checkout: (press enter for '$GH_USERNAME')")" BRANCH
    if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi

    echo "$REPO_NAME: Checking out to branch '$BRANCH'..."
    _git fetch && _git checkout $BRANCH || _git checkout -b $BRANCH origin/$BRANCH || _git checkout -b $BRANCH;
}

cmd_git_checkout_if_detached() {
    if _git symbolic-ref HEAD >/dev/null 2>&1; then
        # echo "$REPO_NAME: Already on a branch, no checkout needed."
        return 0
    else
        message 43 ! "$REPO_NAME: Repository is in detached HEAD state."
        cmd_git_checkout_branch
    fi
}
