#!/bin/bash

if [ "$CURRENT_BRANCH" = "main" ]; then
    message 31 "WARNING" "On the 'main' branch, consider switching to a subbranch"
fi