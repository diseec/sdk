#!/bin/bash

if cli_main internet is-online; then
  _git fetch origin
else
  message 31 "⊘" "Disconnected, cannot fetch branch status..."
fi

local_commit=$(_git rev-parse @)
remote_commit=$(_git rev-parse @{u})
base_commit=$(_git merge-base @ @{u})

if [ "$local_commit" != "$remote_commit" ]; then
  if [ "$local_commit" = "$base_commit" ]; then
    message 34 "↑" "Local branch is behind 'origin/$current_branch'"
  else
    message 31 "⇄" "Branch has diverged from 'origin/$current_branch'!"
  fi
fi