#!/bin/sh

. $KIT_DIR/index.sh; # right here it changes the root dir back to the mono

command=$1; shift; case $command in
    kit|ops|devops) $KIT_DIR/cli "$@" ;;
    wor|workspace) cmd_workspace "$@" ;;
    eve|event) cmd_event "$@" ;;
    upd|update) . $KIT_SRC_DIR/cmds/update.sh; cmd_update "$@" ;;
    git) . $KIT_SRC_DIR/git.sh; cmd_git "$@" ;;
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
