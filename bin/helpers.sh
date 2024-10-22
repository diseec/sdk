#!/bin/bash

CLI_STARTER_FILE="cli"

capitalize() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

color() {
    local color=$1; local text=$2;
    printf "\e[${color}m${text}\e[0m"
}

message(){
  printf "\e[30;47m DISEEC \e[0m"
  if [ $# -eq 1 ]; then printf " $1 ";
  elif [ $# -eq 2 ]; then color "$1" " $(capitalize "$2") ";
  else color "$1" " $(capitalize "$2") "; printf " $3 "; fi
  printf "\n"
}

are_you_sure() {
  local text=$1
  read -p "\e[33m${text}\e[0m\n (y/n) " -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
}

display_help() {
    color 0 "\n"
    color 30 "Usage:\n"
    color 0 "    command [options] [arguments]\n"
    color 0 "\n"
    color 0 "Commands:\n"
    
    # Loop through the arguments and print them
    while [ "$#" -gt 0 ]; do
        command=$1
        description=$2
        color 0 "  $command          $description\n"
        shift 2
    done

    color 0 "\n"
    message 44 info "This cli is designed to run only in it's container\n"
    color 0 "Copyright (c) 2018 DISEEC, all rights reserved.\n\n"
    color 0 "This software and associated documentation files (the \"Software\") are the exclusive property of DISEEC and are protected by copyright and other intellectual property laws. Permission is hereby granted, free of charge, to any person obtaining a copy of this Software, to use the Software within the organization only.\n\n"
    color 0 "\e[1mWebsite \e[0m  https://diseec.com\n"
    color 0 "\e[1mGitHub \e[0m   https://github.com/diseec\n"
    color 0 "\e[1mLinkedIn \e[0m https://linkedin.com/company/diseec\n"
    printf "\n"
    exit 0
}

# cache the project root
PROJECT_ROOT=""

get_root() {
  if [ -n "$PROJECT_ROOT" ]; then
    echo "$PROJECT_ROOT"
    return
  fi

  dir=$(dirname "$0")
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/$CLI_STARTER_FILE" ]; then
      PROJECT_ROOT="$dir"
      echo "$PROJECT_ROOT"
      return
    fi
    dir="$(dirname "$dir")"
  done

  message error "Could not find project root" >&2
  exit 1
}

cli(){
  "$(get_root)/$CLI_STARTER_FILE" "$@"
}

load_env() {
  if [ ! -f "$(get_root)/.env" ]; then
    cp "$(get_root)/.env.example" "$(get_root)/.env"
  fi
  source "$(get_root)/.env"
}
