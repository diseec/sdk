#!/bin/sh

. $CLI_SRC/exports.sh;

command=$1; shift; case $command in
    version|--version) cmd_version "$@" ;;
    *) cmd_unknown "$@" ;;
esac
