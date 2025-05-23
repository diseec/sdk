#!/bin/bash

source $(dirname "$0")/../helpers.sh

# Get the command
case $1 in
  compose)
    shift
    export WWWUSER=$(id -u)
    export WWWGROUP=$(id -g)
    export $(grep -v '^#' $(get_root)/api/.env | xargs)
    docker-compose -f $(get_root)/docker-compose.yml "$@"
    ;;
  build)
    shift
    execute bin/cli/docker/build "$@"
    ;;
  --help|-h)
    color_output 33 "Commands:"
    color_output 0 "    \e[32mbuild\e[0m            build the docker image"
    exit 0
    ;;
esac
