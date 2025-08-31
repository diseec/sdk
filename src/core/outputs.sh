#!/bin/bash

capitalize() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

color() {
    ansi="$1"; shift; text="$@";
    printf "\033[${ansi}m${text}\033[0m"
}

message() {
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ ANSI COLOR & STYLE CHEAT SHEET FOR BASH TERMINAL OUTPUT                 ┃
# ┃ Use: printf "\033[<codes>mYour Text\033[0m"                             ┃
# ┃ Or: color "<codes>" "Your Text"                                         ┃
# ┃ Multiple codes can be combined with semicolons (e.g. "1;31")            ┃
# ┃                                                                         ┃
# ┃ TEXT COLORS (FOREGROUND)                                                ┃
# ┃   30  Black      31  Red        32  Green      33  Yellow               ┃
# ┃   34  Blue       35  Magenta    36  Cyan       37  White                ┃
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
# ┃   color 31 "Red text"                                                   ┃
# ┃   color "1;32" "Bold green text"                                        ┃
# ┃   color "4;34" "Underlined blue text"                                   ┃
# ┃   printf "\033[41;97mWhite on red background\033[0m"                    ┃
# ┃                                                                         ┃
# ┃ Reference: https://en.wikipedia.org/wiki/ANSI_escape_code               ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    local repo_name=${REPO_NAME:-d}
    local prompt="[$(date "+%H:%M:%S")][$(capitalize "$repo_name")]"
    local ansi="90"
    local type="--log"
    local icon=""
    local content=""
    local level="VERBOSE" # VERBOSE > DEBUG > INFO > WARNING > ERROR


    if [ $# -eq 1 ]; then type="--log"; content="$1";
    elif [ $# -eq 2 ]; then type="$1"; content="$2";
    else ansi="$1"; type="$1"; icon="$2"; shift 2; content="$@"; fi

    case $type in
        -l|--log)       ansi="90"; icon="";  level="VERBOSE" ;;
        -d|--debug)     ansi="90"; icon="¤"; level="DEBUG"   ;;
        -f|--fail)      ansi="31"; icon="✖"; level="ERROR"   ;; # ✗
        -e|--error)     ansi="31"; icon="E"; level="ERROR"   ;;
        -o|--okey)      ansi="32"; icon="✓"; level="INFO"    ;; # ✔
        -w|--warning)   ansi="33"; icon="!"; level="WARNING" ;;
        -i|--info)      ansi="34"; icon="i"; level="INFO"    ;;
        -q|--question)  ansi="35"; icon="?"; level="INFO"    ;;
        -a|--ai)        ansi="36"; icon="✦"; level="INFO"    ;;
        -s|--statement) ansi="37"; icon="";  level="INFO"    ;;
        *)                                   level="VERBOSE" ;;
    esac

    if [ -n "$icon" ]; then prompt="$prompt$(color $ansi "[$icon]")"; fi

    case $D_LOG_LEVEL in
        VERBOSE|verbose) ;;
        DEBUG|debug) case $level in VERBOSE) return 0; esac ;;
        INFO|info) case $level in VERBOSE|DEBUG) return 0; esac ;;
        WARNING|warning) case $level in VERBOSE|DEBUG|INFO) return 0; esac ;;
        ERROR|error) case $level in VERBOSE|DEBUG|INFO|WARNING) return 0; esac ;;
    esac

    printf "$prompt $content\n"
}

confirm() {
    local question=$1; shift;
    # read -n 1 -p "$(message 35 "?" "$question \033[35m[Y/N]\033[0m")" response

    printf "$(message 35 "?" "$question \033[35m[Y/N]\033[0m")"
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
        color 34 "$command"
        color 0 "$description\n"
        shift 2
    done
    printf "\n"
}
