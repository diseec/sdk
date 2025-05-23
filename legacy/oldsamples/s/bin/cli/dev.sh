#!/bin/bash

source $(dirname "$0")/../helpers.sh

if [ $# -eq 0 ]; then
  message "No services specified, starting all services..."
  
  bash $0 --only-api &
  bash $0 --only-web &
fi

for arg in "$@"; do
  case $arg in
    --only-api|-i)
      shift
      cli api dev & pid_api=$!
      ;;
    --only-web|-w)
      shift
      cli web dev & pid_web=$!
      ;;
    --help|-h)
      color_output 33 "Options:"
      color_output 0 "    \e[32m-i, --only-api\e[0m        Only start api server"
      color_output 0 "    \e[32m-w, --only-web\e[0m        Only start web server"
      printf "\n"
      color_output 0 "\e[33mNote:\e[0m By default the api and web and db servers are started"
      exit 0
      ;;
  esac
done

# wait for all servers to stop
wait $pid_api $pid_web