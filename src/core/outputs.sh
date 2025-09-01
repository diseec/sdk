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

    ansi="$1"; shift; text="$*";
    printf "\033[0m\033[%sm%s\033[0m" "$ansi" "$text"
}

logger() {
    local repo_name=${REPO_NAME:-d}
    local _ansi="90"
    local type="--log"
    local icon=""
    local content=""
    local level="DEBUG" # DEBUG > INFO > WARNING > ERROR

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
                icon="${1#*=}"
                shift
                ;;
            --ansi=*)
                _ansi="${1#*=}"
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
        -l|--log)       _ansi="90"; icon="";  level="DEBUG" ;;
        -d|--debug)     _ansi="31"; icon="¤"; level="DEBUG" ;;
        -f|--fail)      _ansi="31"; icon="✖"; level="ERROR"   ;; # ✗
        -e|--error)     _ansi="31"; icon="E"; level="ERROR"   ;;
        -o|--okey)      _ansi="32"; icon="✓"; level="INFO"    ;; # ✔
        -w|--warning)   _ansi="33"; icon="!"; level="WARNING" ;;
        -i|--info)      _ansi="34"; icon="i"; level="INFO"    ;;
        -q|--question)  _ansi="35"; icon="?"; level="INFO"    ;;
        -a|--ai)        _ansi="36"; icon="✦"; level="INFO"    ;;
        -s|--statement) _ansi="97"; icon="";  level="INFO"    ;;
        *)                                   level="DEBUG" ;;
    esac

    # Prepare prompt & content
    local prompt="[$(date "+%H:%M:%S")][$(capitalize "$repo_name")]"
    prompt="$(ansi 90 "$prompt")"
    if [ -n "$icon" ]; then prompt="$prompt$(ansi $_ansi "[$icon]")"; fi

    # Only colorize content if it's not empty
    if [ -n "$content" ]; then
        content="$(ansi 90 "$content")"
    fi

    # Handle logging levels
    case $D_LOG_LEVEL in
        DEBUG|debug) ;;
        INFO|info) case $level in       DEBUG) return 0; esac ;;
        WARNING|warning) case $level in DEBUG|INFO) return 0; esac ;;
        ERROR|error) case $level in     DEBUG|INFO|WARNING) return 0; esac ;;
    esac

    # Output log message
    printf "%s %s\n" "$prompt" "$content"
}

confirm() {
    local question=$1; shift;

    printf "$(logger --ansi="35" --icon="?" "$question \033[35m[Y/N]\033[0m")"
    # Turn off echo and set input to raw mode
    stty -echo -icanon time 0 min 1
    response=$(dd bs=1 count=1 2>/dev/null)
    # Restore terminal settings
    stty echo icanon

    printf "\n"
    case "$response" in
        [yY][eE][sS]|[yY]) "$@"; return 0 ;;
        [nN][oO]|[nN]) return 1 ;;
        *) ;;
    esac
}

display_help() {
    # Loop through the arguments and print them
    while [ "$#" -gt 0 ]; do
        command=$1
        description=$2
        ansi 97 "$command"
        ansi 90 "$description"
        printf "\n"
        shift 2
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