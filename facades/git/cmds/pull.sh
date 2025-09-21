#!/bin/bash

sdk_fac_git_cmd_pull_merge() {
    stdout -i --processing "Fetching latest changes from remote"

    stdout -l --processing "Pulling latest branch '$D_CURRENT_BRANCH' changes"
    retry --auto --manual "_git -C \"$D_CTX_DIR\" pull origin" pull_output
    if ! [ $? -eq 0 ]; then
        echo $pull_output
        stdout -e "Failed to pull latest changes from 'origin/$D_CURRENT_BRANCH'"
        return 1
    fi

    stdout -l --processing "Merging latest 'origin/main' changes to branch '$D_CURRENT_BRANCH'"
    retry --auto --manual "_git -C \"$D_CTX_DIR\" merge origin/main" merge_output
    if ! [ $? -eq 0 ]; then
        echo $merge_output
        stdout -e "Failed to merge latest 'origin/main' changes to branch '$D_CURRENT_BRANCH'"
        return 1
    fi


    stdout -l "Pull and merge complete."

    if [ "$D_GLOB_RECURSIVE" = "true" ]; then
        pull_submodule() {
            stdout -l --processing "Pull and merging in submodule '$module'"
            local module="$1"
            local module_path="$2"
            retry --auto --manual "bash \"$D_CTX_DIR/$module_path/$D_CLI_LOCAL_NAME\" api v1 pull" submodule_pull_output
            if ! [ $? -eq 0 ]; then
                echo $submodule_pull_output
                stdout -e "Failed to pull latest changes in submodule '$module' at '$module_path'"
                return 1
            fi
            return 0
        }
        cli_ctx submodule foreach_active pull_submodule
    fi
}
