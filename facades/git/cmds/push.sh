#!/bin/bash

sdk_fac_git_cmd_push() {
    # Push to remote
    stdout -l --processing "Pushing to remote"
    
    retry --auto --manual "_git push -u origin \"$D_CURRENT_BRANCH\""
    if [ $? -ne 0 ]; then
        stdout -e "Failed to push changes to remote."
        return 1
    fi

    return 0
}
