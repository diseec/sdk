#!/bin/bash

c=$1; shift; case $c in
    pro|project) SRC_KIT "facades/setup/project.sh" "$@" ;;
    pre|prettier) SRC_KIT "facades/setup/prettier.sh" "$@" ;;
    sys|system) SRC_KIT "facades/setup/system.sh" "$@" ;;
    upd|update) SRC_KIT "facades/setup/update.sh" "$@" ;;
    glo|globally) SRC_KIT "facades/setup/globally.sh" "$@" ;;
    "");;*)
        echo "Usage: $0 <command>"
        echo "Available commands:"
        echo "    pro|project   Setup project"
        echo "    pre|prettier  Setup Prettier"
        echo "    sys|system    Setup system"
        echo "    upd|update    Setup update"
        echo "    glo|globally  Setup globally"
        ;;
esac
