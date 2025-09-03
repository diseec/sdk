#!/bin/bash

capitalize() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

ansi() {
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ ANSI COLOR & STYLE CHEAT SHEET FOR BASH TERMINAL OUTPUT                 ┃
# ┃ Use: printf "\033[<codes>mYour Text\033[0m"                             ┃
# ┃ Or: ansi "<codes>" "Your Text"                                          ┃
# ┃ Multiple codes can be combined with semicolons (e.g. "1;31")            ┃
# ┃                                                                         ┃
# ┃ TEXT COLORS (FOREGROUND)                                                ┃
# ┃   30  Black      31  Red        32  Green      33  Yellow               ┃
# ┃   34  Blue       35  Magenta    36  Cyan       97  White                ┃
# ┃   90  Bright Black (Gray)      91  Bright Red                           ┃
# ┃   92  Bright Green             93  Bright Yellow                        ┃
# ┃   94  Bright Blue              95  Bright Magenta                       ┃
# ┃   96  Bright Cyan              97  Bright White                         ┃
# ┃                                                                         ┃
# ┃ BACKGROUND COLORS                                                       ┃
# ┃   40  Black      41  Red        42  Green      43  Yellow               ┃
# ┃   44  Blue       45  Magenta    46  Cyan       47  White                ┃
# ┃   100 Bright Black   101 Bright Red   102 Bright Green                  ┃
# ┃   103 Bright Yellow  104 Bright Blue  105 Bright Magenta                ┃
# ┃   106 Bright Cyan    107 Bright White                                   ┃
# ┃                                                                         ┃
# ┃ TEXT STYLES                                                             ┃
# ┃   0   Reset/Normal   1   Bold        2   Dim                            ┃
# ┃   3   Italic         4   Underline   5   Blink                          ┃
# ┃   7   Inverse        8   Hidden                                         ┃
# ┃                                                                         ┃
# ┃ EXAMPLES                                                                ┃
# ┃   ansi 31 "Red text"                                                    ┃
# ┃   ansi "1;32" "Bold green text"                                         ┃
# ┃   ansi "4;34" "Underlined blue text"                                    ┃
# ┃   printf "\033[41;97mWhite on red background\033[0m"                    ┃
# ┃                                                                         ┃
# ┃ Reference: https://en.wikipedia.org/wiki/ANSI_escape_code               ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    local ansi="$1"; shift; local text="$@";
    printf "\033[0m\033[%sm%s\033[0m" "$ansi" "$text"
}

logit() {
    local level="DEBUG" # DEBUG > INFO > WARNING > ERROR
    local repo_name=${REPO_NAME:-d}
    local type="--log"
    local default_ansi="90"
    local default_icon=""
    local content=""

    # First, check if the first argument is a valid type
    if [ $# -gt 0 ]; then
        case "$1" in
            -l|-d|-f|-e|-o|-w|-i|-q|-a|-s)
                type="$1"
                shift
                ;;
        esac
    fi
    
    # Now process the rest of the arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --icon=*)
                local given_icon="${1#*=}"
                shift
                ;;
            --ansi=*)
                local given_ansi="${1#*=}"
                shift
                ;;
            *)
                # All remaining arguments form the content
                content="$*"
                break
                ;;
        esac
    done

    # Parse type config
    case $type in
        -l|--log)       default_ansi="90"; default_icon="";  level="DEBUG" ;;
        -d|--debug)     default_ansi="31"; default_icon="¤"; level="DEBUG" ;;
        -f|--fail)      default_ansi="31"; default_icon="✖"; level="ERROR"   ;; # ✗
        -e|--error)     default_ansi="31"; default_icon="E"; level="ERROR"   ;;
        -o|--okey)      default_ansi="32"; default_icon="✓"; level="INFO"    ;; # ✔
        -w|--warning)   default_ansi="33"; default_icon="!"; level="WARNING" ;;
        -i|--info)      default_ansi="34"; default_icon="i"; level="INFO"    ;;
        -q|--question)  default_ansi="35"; default_icon="?"; level="INFO"    ;;
        -a|--ai)        default_ansi="96"; default_icon="✦"; level="INFO"    ;;
        -s|--statement) default_ansi="97"; default_icon="";  level="INFO"    ;;
        *)                                                   level="DEBUG" ;;
    esac

    # Prepare icon and ANSI color
    local _ansi="${given_ansi:-$default_ansi}"
    local _icon="${given_icon:-$default_icon}"

    # Prepare prompt & content
    local prompt="[$(date "+%H:%M:%S")][$(capitalize "$repo_name")]"
    prompt="$(ansi 90 "$prompt")"
    if [ -n "$_icon" ]; then prompt="$prompt$(ansi $_ansi "[$_icon]")"; fi

    # Only colorize content if it's not empty
    if [ -n "$content" ]; then
        content="$(ansi 90 "$content")"
    else
        content="An empty log!";
    fi

    # Handle logging levels
    case $D_LOG_LEVEL in
        DEBUG|debug) ;;
        INFO|info) case $level in       DEBUG) return 0; esac ;;
        WARNING|warning) case $level in DEBUG|INFO) return 0; esac ;;
        ERROR|error) case $level in     DEBUG|INFO|WARNING) return 0; esac ;;
    esac

    # Output log message
    printf "%s %b\n" "$prompt" "$content"
}

# Function for use in if statements - returns 0 (true) or 1 (false)
confirm() {
    # usage:
    # if confirm "Do you want to proceed?"; then
    #     # Your code here for the "yes" case
    # else
    #     # Your code here for the "no" case
    # fi
    # OR
    # confirm "Do you want to proceed?" echo 'does this!'

    local question=$1; shift
    
        # Store original terminal settings to restore later
        local old_settings=$(stty -g)
    
        # Enable proper signal handling (especially Ctrl+C)
        trap 'stty "$old_settings"; echo ""; return 1' INT TERM
    
    printf "$(logit --ansi="35" --icon="?" "$question \033[35m[Y/N]\033[0m")"
    
    # Read a single character, but allow signal handling
    stty -echo -icanon
    local response=$(head -c1)
    
        # Restore terminal settings
        stty "$old_settings"
        trap - INT TERM

    printf "\n"
    
    case "$response" in
        [yY][eE][sS]|[yY])
            if [ $# -gt 0 ]; then "$@"; fi
            return 0
            ;; # Return 0 for success/true in bash
        [nN][oO]|[nN]) return 1 ;; # Return 1 for failure/false in bash
        *)
            # Invalid response, prompt again
            logit -e "Invalid response. Please enter Y or N."
            # Recursive call to retry - pass all original arguments
            confirm "$question" "$@"
            return $?
            ;;
    esac
}

display_help() {
    # Loop through the arguments and print them
    while [ "$#" -gt 0 ]; do
        local command=$1
        local description=$2
        ansi 97 "$command"
        ansi 90 "$description"
        printf "\n"
        if [ "$#" -ge 2 ]; then shift 2
        else shift; fi
    done
    printf "\n"
}

about() {
    printf "\n"
    printf "\e[47m    $(capitalize $ORG_NAME) DevOps CLI \e[0m\e[1m\e[34m Automation Toolkit \e[0m\e[97mv$VERSION\n\e[0m"
    printf "\n"
    printf "\e[90mThis software and associated documentation files\n(the \"Software\") are the  exclusive property  of\n$(capitalize $ORG_NAME) L.T.E. and are protected by copyright and\nother intellectual property laws.\nPermission is hereby granted, free of charge, to\nany person obtaining a copy of this Software, to\nse the Software within the organization only.\n\e[0m"
    printf "\n"
    printf "\e[90m\e[1mWebsite  \e[0m\e[90m    https://$ORG_NAME.com\n\e[0m"
    printf "\e[90m\e[1mGitHub   \e[0m\e[90m    https://github.com/$ORG_NAME\n\e[0m"
    printf "\e[90m\e[1mLinkedIn \e[0m\e[90m    https://linkedin.com/company/$ORG_NAME\n\e[0m"
    printf "\n"
    printf "\e[90mCopyright (c) 2018 $(capitalize $ORG_NAME),  all rights  reserved\n\e[0m"
    printf "\n"
}