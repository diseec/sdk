#!/bin/sh

. $CLI_ROOT/index.sh;

command=$1; shift; case $command in
    version|--version) cmd_version "$@" ;;
    envs)
        # Source projects root cli to load environment variables. example: "source ./cli envs;"
    ;;
    *) cmd_unknown "$@" ;;
esac
