#!/bin/bash

source $(dirname "$0")/../helpers.sh

# Check for --help option 
for arg in "$@"; do
  case $arg in
    connect)
      shift
      ssh -o ServerAliveInterval=4000 -i ~/Projects/satyp/aws/satyp-aws-key-pair-ec2.pem ubuntu@52.91.127.45 "$@"
      ;;
    --help|-h)
      # printf "\n"
      # color_output 33 "Options:"
      # color_output 0 "    \e[32m--help\e[0m       Display help for the given command. When no command is given display help for the list command"
      # printf "\n"
      color_output 33 "Commands:"
      color_output 0 "    \e[32mconnect\e[0m   Connect to the production server over ssh"
      exit 0
      ;;
  esac
done
