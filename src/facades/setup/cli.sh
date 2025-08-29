#!/bin/bash

c=$1; shift; case $c in
    pro|project) fac_set_project "$@" ;;
    pre|prettier) fac_set_prettier "$@" ;;
    upd|update) fac_set_update "$@" ;;
    glo|globally) fac_set_globally "$@" ;;
    sys|system) c=$1; shift; case $c in
        dep|dependency-check)
            fac_set_check_system_dependencies
        ;;
        ins|install)
            fac_set_install_system_dependencies
        ;;
        hel|help|--help|-h)
            echo "Usage: $0 {dependency-check|install}"
            echo "  is|is-missing-dependencies - Check for missing system dependencies"
            echo "  dep|dependency-check - Check system dependencies"
            echo "  ins|install - Install system dependencies defined in package.json"
        ;;
    esac ;;
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
