#!/bin/bash

# Check if GitHub CLI is installed
check_gh_cli() {
  if ! command -v _gh >/dev/null 2>&1; then
    message 31 "ERROR" "GitHub CLI (gh) is not installed. Please install it first:"
    return 1
  fi
  
  # Check if authenticated
  if ! _gh auth status >/dev/null 2>&1; then
    message 31 "ERROR" "GitHub CLI is not authenticated."
    return 1
  fi
  
  return 0
}


