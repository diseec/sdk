#!/bin/bash

if [ "$CURRENT_BRANCH" = "main" ]; then
    message 41 "!" "On the 'main' branch, consider switching to a subbranch"
fi