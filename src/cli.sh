#!/bin/sh

. $CLI_ROOT/index.sh;

command=$1; shift; case $command in
    devops) $CLI_ROOT/cli "$@" ;;
    workspace) cmd_workspace "$@" ;;
    version|--version) cmd_version "$@" ;;
    envs)
        # Source projects root cli to load environment variables. example: "source ./cli envs;"
        message 34 "info" "Sourced repo envs"
    ;;
    *) 
        informer check-for-updates
        cmd_unknown "$@" 
    ;;
esac
