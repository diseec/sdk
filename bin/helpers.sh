#!/bin/bash

CLI_STARTER_FILE="cli"

# color the output of the text
color_output() {
    local color=$1
    local text=$2
    printf "\e[${color}m${text}\e[0m\n"
}

message(){
  load_env
  
  printf "\e[30;47m @$APP_NAME \e[0m"
  if [ $# -eq 1 ]; then
    type="\e[30;46m message \e[0m"
    text=$1
  else
    type=$1
    text=$2
  fi

  case $type in
    error|err|e|fail|failed|f)
      printf "\e[41m ERROR \e[0m $text"
      ;;
    okey|ok|success|s|done|d)
      printf "\e[42m DONE \e[0m $text"
      ;;
    warning|warn|w|caution|c|alert|attention|attn|a)
      printf "\e[43m WARN \e[0m $text"
      ;;
    info|i|notice|note|n)
      printf "\e[44m INFO \e[0m $text"
      ;;
    command|cmd)
      printf "\e[45m $ \e[0m $text"
      ;;
    *)
      printf "$type $text"
      ;;
  esac
  printf "\n"
}

are_you_sure() {
  local text=$1
  read -p "\e[33m${text}\e[0m\n (y/n) " -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
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
