#!/bin/bash

capitalize() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

color() {
    color=$1; text=$2;
    printf "\033[${color}m${text}\033[0m"
}

message() {
  # TODO change api to:
  #             message <text> # silently echos with only repo name and date (?)
  #             message <type> <text>
  #             message --color <color> --title <title> <text>
  local repo_name=${REPO_NAME:-d}
  printf "\e[1;30;47m $(capitalize "$repo_name") \e[0m"
  if [ $# -eq 1 ]; then printf " $1 ";
  elif [ $# -eq 2 ]; then color "$1" " $(capitalize "$2") ";
  else color "$1" " $(capitalize "$2") "; printf " $3 "; fi
  printf "\n"
}

ask_to_run_command() {
  local question=$1; shift;
  # read -n 1 -p "$(message 45 "?" "$question \033[35m[y/n]\033[0m")" response

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
    # Loop through the arguments and print them
    while [ "$#" -gt 0 ]; do
        command=$1
        description=$2
        color 34 "$command"
        color 0 "$description\n"
        shift 2
    done

    color 0 "\n"
    color 0 "\n"
    color 0 "\e[1mv$VERSION DISEEC DevOps CLI\e[0m — Automation Toolkit\n"
    printf "\n"
    color 0 "This software and associated documentation files\n(the \"Software\") are the  exclusive property  of\nDISEEC L.T.E. and are protected by copyright and\nother intellectual property laws.\nPermission is hereby granted, free of charge, to\nany person obtaining a copy of this Software, to\nse the Software within the organization only.\n\n"
    color 0 "\e[1mWebsite \e[0m  https://diseec.com\n"
    color 0 "\e[1mGitHub \e[0m   https://github.com/diseec\n"
    color 0 "\e[1mLinkedIn \e[0m https://linkedin.com/company/diseec\n"
    printf "\n"
    color 0 "Copyright (c) 2018 DISEEC, all rights reserved.\n\n"
    printf "\n"
}
