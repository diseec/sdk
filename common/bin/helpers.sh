#!/bin/sh

# export REPO_NAME=$(grep 'url = ' ./.git/config | awk -F'/' '{print $NF}' | sed 's/\.git$//')

capitalize() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

color() {
    local color=$1; local text=$2;
    printf "\e[${color}m${text}\e[0m"
}

message(){
  printf "\e[1;30;47m D \e[0m"
  if [ $# -eq 1 ]; then printf " $1 ";
  elif [ $# -eq 2 ]; then color "$1" " $(capitalize "$2") ";
  else color "$1" " $(capitalize "$2") "; printf " $3 "; fi
  printf "\n"
}


ask_to_run_command() {
  local question=$1; shift;
  # read -n 1 -p "$(message 45 "⁇" "$question \033[35m[y/n]\033[0m")" response

  printf "$(message 45 "?" "$question \033[35m[y/n]\033[0m")"
  # Turn off echo and set input to raw mode
  stty -echo -icanon time 0 min 1
  response=$(dd bs=1 count=1 2>/dev/null)
  # Restore terminal settings
  stty echo icanon

  printf "\n"
  case "$response" in
    [yY][eE][sS]|[yY])
      "$@"
      ;;
    [nN][oO]|[nN])
      ;;
    *)
      ;;
  esac
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
    color 0 "Copyright (c) 2018 DISEEC, all rights reserved.\n\n"
    color 0 "This software and associated documentation files (the \"Software\") are the exclusive property of DISEEC and are protected by copyright and other intellectual property laws. Permission is hereby granted, free of charge, to any person obtaining a copy of this Software, to use the Software within the organization only.\n\n"
    color 0 "\e[1mWebsite \e[0m  https://diseec.com\n"
    color 0 "\e[1mGitHub \e[0m   https://github.com/diseec\n"
    color 0 "\e[1mLinkedIn \e[0m https://linkedin.com/company/diseec\n"
    printf "\n"
    exit 0
}

informer() {
  case "$1" in
    sync-registry-image)
    export REPO_NAME="$PROJECT_NAME-$PROJECT_VERSION"""
      # IMAGE_NAME="$REGISTRY_URL/$REPO_NAME"
      # Attempt to get the local image digest
      LOCAL_DIGEST=$(docker image inspect $IMAGE_NAME --format='{{index .RepoDigests 0}}' 2>/dev/null || echo "")
      # Check if the local digest retrieval was an error
      if [ -n "$LOCAL_DIGEST" ]; then
          message 43 "⇊" "Using image from registry"
      fi
      # if [ -z "$LOCAL_DIGEST" ]; then
      #     message 43 "⎋" "Using locally built image"
      # else
      #     message 43 "⇊" "Using image from registry"
      # fi
    ;;

    forbid-dev-on-main)
      current_branch=$(git rev-parse --abbrev-ref HEAD)
      if [ "$current_branch" = "main" ]; then
          message 41 "!" "On the 'main' branch, consider switching to 'dev' branch"
      fi
    ;;

    summary-branch-status)
      if ping -c 1 google.com > /dev/null 2>&1; then
          git fetch origin
      fi
      local_commit=$(git rev-parse @)
      remote_commit=$(git rev-parse @{u})
      base_commit=$(git merge-base @ @{u})
      if [ "$local_commit" != "$remote_commit" ]; then
        if [ "$local_commit" = "$base_commit" ]; then
          message 44 "⟳" "Updates available on 'origin/$current_branch'"
        else
          message 41 "↫" "Branch has diverged from 'origin/$current_branch'!"
        fi
      fi
    ;;
  esac
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

load_env() {
  if [ ! -f "$(get_root)/.env" ]; then
    cp "$(get_root)/.env.example" "$(get_root)/.env"
  fi
  source "$(get_root)/.env"
}

execute_command_in_container() {
    local SERVICE_NAME=$1; shift;

    if [ -n "$CI" ]; 
        then OPTIONS="-e CI=true";
        else OPTIONS="-it";
    fi

    if docker compose ps -q "$SERVICE_NAME" | grep -q .; then
        message 34 $SERVICE_NAME "Already running, Executing command .."
        docker compose exec $OPTIONS "$SERVICE_NAME" "$@"
    else
        message 34 $SERVICE_NAME "Executing command in a fresh instance .."
        docker compose run --rm $OPTIONS "$SERVICE_NAME" "$@"
    fi
}