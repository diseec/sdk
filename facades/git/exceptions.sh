#!/bin/bash

# Check if GitHub cli is installed
sdk_fac_git_cmd_check_gh_cli() {
  if ! command -v _gh >/dev/null 2>&1; then
    stdout -e "GitHub cli (gh) is not installed. Please install it first:"
    return 1
  fi
  
  # Check if authenticated
  if ! _gh auth status >/dev/null 2>&1; then
    stdout -e "GitHub cli is not authenticated."
    return 1
  fi
  
  return 0
}


