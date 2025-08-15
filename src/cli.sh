#!/bin/sh

. $CLI_ROOT/index.sh;

command=$1; shift; case $command in
    workspace) cmd_workspace "$@" ;;
    version|--version) cmd_version "$@" ;;
    envs)
        # Source projects root cli to load environment variables. example: "source ./cli envs;"
        message 34 "info" "Sourced repo envs"
    ;;
    *) 
        # Check for updates quietly
        check_for_updates
        cmd_unknown "$@" 
    ;;
esac
