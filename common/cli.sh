#!/bin/sh

cd $(dirname "$0");
. "./bin/envs.sh";
. "./bin/helpers.sh";
. "./bin/cmds.sh";
command=$1; shift;
 
case $command in
    version|--version)          cmd_version "$@" ;;
esac