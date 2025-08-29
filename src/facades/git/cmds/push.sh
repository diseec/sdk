#!/bin/bash

fac_git_cmd_push() {
  set -e
  # Push to remote
  echo "Pushing to remote..."
  _git push -u origin "$CURRENT_BRANCH"
  if [ $? -ne 0 ]; then
    message 41 "!" "Failed to push changes to remote."
    return 1
  fi

  return 0
}
