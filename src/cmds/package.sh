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
            _git rm -f packages/$1;
    ;;

    update)
        _git submodule update --remote --merge
    ;;

    link)
        message "45" "PACKAGES:" "\n$(ls packages)"
        read -p "$(message 45 "?" "Select a package to link:")" PACKAGE
        _npm link ./packages/$PACKAGE
    ;;

    *)
        message 33 "PACKAGE" "Available package commands:"
        echo "  add <name>       - Add package as git submodule"
        echo "  remove|rm <name> - Remove package submodule"
        echo "  update           - Update all package submodules"
        echo "  link             - Link local package for development"
        echo ""
        echo "Usage: cli package <command> [package-name]"
        exit 1
    ;;
esac