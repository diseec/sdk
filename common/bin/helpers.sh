#!/bin/sh

capitalize() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

color() {
    color=$1; text=$2;
    printf "\033[${color}m${text}\033[0m"
}

message(){
  local repo_name=${REPO_NAME:-d}
  printf "\e[1;30;47m $(capitalize "$repo_name") \e[0m"
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
    color 33 "Usage:\n"
    color 32 "    command [options] [arguments]\n"
    color 0 "\n"
    color 33 "Commands (Global):\n"
    
    # Loop through the arguments and print them
    while [ "$#" -gt 0 ]; do
        command=$1
        description=$2
        color 34 "$command"
        color 0 "$description\n"
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

    forbid-dev-on-main)
      current_branch=$(git rev-parse --abbrev-ref HEAD)
      if [ "$current_branch" = "main" ]; then
          message 41 "!" "On the 'main' branch, consider switching to a subbranch"
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

execute_command_in_container() {
    local SERVICE_NAME=$1; shift;

    if [ -n "$CI" ]; 
        then OPTIONS="-e CI=true";
        else OPTIONS="-it";
    fi

    if [ "$IS_IN_CONTAINER" = "true" ]; then
        message 34 $SERVICE_NAME "Inside container, Executing command .."
        "$@"
    else
      if docker compose ps -q "$SERVICE_NAME" | grep -q .; then
          message 34 $SERVICE_NAME "Already running, Executing command .."
          docker compose exec $OPTIONS "$SERVICE_NAME" "$@"
      else
          message 34 $SERVICE_NAME "No running container found, Starting a fresh instance .."
          docker compose run --rm $OPTIONS "$SERVICE_NAME" "$@"
      fi
    fi
}
