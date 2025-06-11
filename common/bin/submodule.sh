#!/bin/sh

command=$1; shift; cd $ROOT_DIR;

case $command in

    add)
        message "Adding submodule '$1' .."
        set -e;
        git submodule add https://$REPOSITORY_URL/$1.git modules/$1
        git submodule update --init --recursive
    ;;

    remove|rm)
        ask_to_run_command "Are you sure, remove the submodule '$1'?" \
            set -e; \
            git submodule deinit -f -- modules/$1; \
            rm -rf .git/modules/modules/$1; \
            git rm -f modules/$1;
    ;;

    update)
        git submodule update --remote --merge
    ;;

    *)
        echo "Usage: $0 submodule [add|remove|update] <submodule-name>"
        exit 1
    ;;
esac