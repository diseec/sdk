#!/bin/sh

. $CLI_ROOT/index.sh;

command=$1; shift; case $command in
    kit|ops|devops) $CLI_ROOT/cli "$@" ;;
    wor|workspace) cmd_workspace "$@" ;;
    eve|event) cmd_event "$@" ;;
    upd|update) . $CLI_SRC/cmds/update.sh; cmd_update "$@" ;;
    git) . $CLI_SRC/git.sh; cmd_git "$@" ;;
    ver|version|--version) cmd_version "$@" ;;
    env|envs)
        # Source projects root cli to load environment variables. example: "source ./cli envs;"
        message 34 "info" "Sourced repo envs"
    ;;
    *) 
        # informer check-for-updates
        cmd_unknown "$@" 
    ;;
esac
