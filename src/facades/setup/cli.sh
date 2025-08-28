#!/bin/bash

source "$KIT_SRC_DIR/facades/setup/index.sh"

c=$1; shift; case $c in
    pro|project) setup_project "$@" ;;
    pre|prettier) setup_prettier "$@" ;;
    sys|system) setup_system "$@" ;;
    upd|update) setup_update "$@" ;;
    glo|globally) setup_globally "$@" ;;
    hel|help|--help|-h)
        echo "Usage: $0 <command>"
        echo "Available commands:"
        echo "    pro|project   Setup project"
        echo "    pre|prettier  Setup Prettier"
        echo "    sys|system    Setup system"
        echo "    upd|update    Setup update"
        echo "    glo|globally  Setup globally"
        ;;
    *) if [ ! -z "$c" ]; then echo "Unknown command: '$c'"; fi ;;
esac
