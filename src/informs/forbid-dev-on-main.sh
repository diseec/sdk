#!/bin/bash

if [ "$CURRENT_BRANCH" = "main" ]; then
    message -w "On the 'main' branch, consider switching to a subbranch"
fi