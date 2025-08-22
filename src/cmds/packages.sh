#!/bin/bash

cd $ROOT_DIR; command=$1; shift;

case $command in

    add)
        message "Adding package '$1' .."
        set -e;
        git submodule add https://$REPO_HUB_URL/$1.git packages/$1
        git submodule update --init --recursive
    ;;

    remove|rm)
        ask_to_run_command "Are you sure, remove the package '$1'?" \
            set -e; \
            git submodule deinit -f -- packages/$1; \
            rm -rf .git/modules/packages/$1; \
            git rm -f packages/$1;
    ;;

    update)
        git submodule update --remote --merge
    ;;

    link)
        message "45" "PACKAGES:" "\n$(ls packages)"
        read -p "$(message 45 "?" "Select a package to link:")" PACKAGE
        npm link ./packages/$PACKAGE
    ;;

    *)
        echo "Usage: $0 package [add|remove|update|link] <package-name>"
        exit 1
    ;;
esac