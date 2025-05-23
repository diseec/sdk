#!/bin/bash

source $(dirname "$0")/../helpers.sh

api_status=0
web_status=0

run_all_tests() {
  bash $0 --only-api
  bash $0 --only-web
}

# Run all if no options are provided
if [ $# -eq 0 ]; then
  run_all_tests
fi

# Check for --only-web, --only-api, or --help options
for arg in "$@"; do
  case $arg in
    --all|-a)
      shift
      run_all_tests "$@"
      ;;
    --only-web|-w)
      shift
      message "Running smoke tests..."
      cli web test --only-smoke --parallel "$@"
      # if exit code is 0, run all tests
      web_status=$?
      if [ $web_status -eq 0 ]; then
        cli web test --parallel "$@"
        web_status=$?
      fi
      ;;
    --only-api|-i)
      shift
      cli api test --parallel --stop-on-failure --stop-on-error "$@"
      api_status=$?
      ;;
    --help|-h)
      color_output 33 "Options:"
      color_output 0 "    \e[32m-a, --all\e[0m            run all tests"
      color_output 0 "    \e[32m-i, --only-api\e[0m       only test the api"
      color_output 0 "    \e[32m-w, --only-web\e[0m       only test the web"
      printf "\n"
      color_output 0 "\e[33mNote:\e[0m By default all available tests will be run"
      exit 0
      ;;
  esac
done

if [ $api_status -ne 0 ] || [ $web_status -ne 0 ]; then
  exit 1
fi