#!/bin/sh

is_true() {
  case "${1,,}" in
    1|true|yes|y|on) return 0 ;;
    *) return 1 ;;
  esac
}

capitalize() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

color() {
    color=$1; text=$2;
    printf "\033[${color}m${text}\033[0m"
}

message() {
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

    check-for-updates)
       . $CLI_SRC/cmds/update.sh; 
      # Skip if we're just running version or help commands
      if [ "$command" = "version" ] || [ "$command" = "--version" ] || [ "$command" = "help" ] || [ "$command" = "update" ]; then
          return 0
      fi

      # Check if version changed or if repo/modules are behind
      if has_version_changed; then
          message 46 "UPDATE" "New updates available!"
          ask_to_run_command "Apply updates now?" "$CLI" update
      elif [ -d "$ROOT_DIR/.git" ]; then
          # Check if the main repository is behind
          current_branch=$(_git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
          if [ $? -eq 0 ] && [ -n "$current_branch" ]; then
              _git -C "$ROOT_DIR" fetch origin >/dev/null 2>&1
              local_commit=$(_git -C "$ROOT_DIR" rev-parse @)
              remote_commit=$(_git -C "$ROOT_DIR" rev-parse "@{u}" 2>/dev/null)
              
              if [ $? -eq 0 ] && [ "$local_commit" != "$remote_commit" ]; then
                  message 43 "UPDATE" "Repository is behind the remote branch!"
                  ask_to_run_command "Apply updates now?" "$CLI" update
              else
                  # Check if any of the selected modules are behind
                  . $CLI_SRC/workspace.sh
                  modules_behind=false
                  
                  check_module_status() {
                      local module="$1"
                      local module_path="$2"
                      local full_path="$ROOT_DIR/$module_path"
                      
                      if [ -d "$full_path/.git" ]; then
                          _git -C "$full_path" fetch origin >/dev/null 2>&1
                          local_commit=$(_git -C "$full_path" rev-parse @ 2>/dev/null)
                          remote_commit=$(_git -C "$full_path" rev-parse "@{u}" 2>/dev/null)
                          
                          if [ $? -eq 0 ] && [ "$local_commit" != "$remote_commit" ]; then
                              modules_behind=true
                              return 1  # Exit the loop early
                          fi
                      fi
                  }
                  
                  foreach_selected_module_with_callback check_module_status
                  
                  if $modules_behind; then
                      message 43 "UPDATE" "Modules are behind their remote branches!"
                      ask_to_run_command "Apply updates now?" "$CLI" update
                  fi
              fi
          fi
      fi
    ;;
  esac
}

execute_command_in_container() {
    local SERVICE_NAME=$1; shift;
    
    while [ $# -gt 0 ]; do case "$1" in
        --no-message) IS_SILENT="true"; shift;;
    *) break;; esac; done;
    
    if [ -n "$CI" ]; 
        then OPTIONS="-e CI=true";
        else OPTIONS="-it";
    fi

    if [ "$IS_IN_CONTAINER" = "true" ]; then
      if [ "$IS_SILENT" != "true" ]; then message 34 $SERVICE_NAME "Inside container, Executing command .."; fi
        "$@"
    else
      if docker compose ps -q "$SERVICE_NAME" | grep -q .; then
          if [ "$IS_SILENT" != "true" ]; then message 34 $SERVICE_NAME "Already running, Executing command .."; fi
          docker compose exec $OPTIONS "$SERVICE_NAME" "$@"
      else
          if [ "$IS_SILENT" != "true" ]; then message 34 $SERVICE_NAME "No running container found, Starting a temporary instance .."; fi
          docker compose run --rm --no-deps $OPTIONS "$SERVICE_NAME" "$@"
      fi
    fi
}
