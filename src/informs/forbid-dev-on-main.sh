#!/bin/bash

current_branch=$(_git rev-parse --abbrev-ref HEAD)

if [ "$current_branch" = "main" ]; then
    message 31 "WARNING" "On the 'main' branch, consider switching to a subbranch"
fi