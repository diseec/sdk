#!/bin/sh

cd $(dirname "$0"); 
. "./bin/envs.sh";
. "./bin/helpers.sh";
. "./bin/cmds.sh";

# if [ -z "$1" ]; then sh cli help; fi
command=$1; shift;
 
case $command in
    install)        cmd_install "$@" ;;
    status)         cmd_status "$@" ;;
    pull)           cmd_pull "$@" ;;
    dev)            cmd_dev "$@" ;;
    pro)            cmd_pro "$@" ;;
    build)          cmd_build "$@" ;;
    run)            cmd_run "$@" ;;
    exec)           cmd_exec "$@" ;;
    shell)          cmd_shell "$@" ;;
    test)           cmd_test "$@" ;;
    release)        cmd_release "$@" ;;
    kit)            cmd_kit "$@" ;;
    submodule)      cmd_submodule "$@" ;;
    help|-h)        cmd_help "$@"  ;;
    *)              cmd_unknown "$@" ;;
esac