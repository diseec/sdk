#!/bin/bash

if ping -c 1 google.com > /dev/null 2>&1; then
  _git fetch origin
fi

local_commit=$(_git rev-parse @)
remote_commit=$(_git rev-parse @{u})
base_commit=$(_git merge-base @ @{u})

if [ "$local_commit" != "$remote_commit" ]; then
  if [ "$local_commit" = "$base_commit" ]; then
    message 34 "UPDATE" "Updates available on 'origin/$current_branch'"
  else
    message 31 "DIVERGED" "Branch has diverged from 'origin/$current_branch'!"
  fi
fi