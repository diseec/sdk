#!/bin/bash

capitalize() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

normalize() {
    # Convert newlines and tabs to spaces, then squeeze multiple spaces into one
    # echo "$1" | tr '\n\t' ' ' | tr -s ' ' | sed 's/^ *//;s/ *$//'
    printf '%s' "$1" | tr '\n\r\t' ' ' | sed 's/  */ /g' | sed 's/^ //; s/ $//'
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
