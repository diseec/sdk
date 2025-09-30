#!/bin/bash

capitalize() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

normalize() {
    # Convert newlines and tabs to spaces, then squeeze multiple spaces into one
    # Check if input contains literal \t or \n sequences and handle them
    local input="$1"
    
    # Handle literal \t and \n if they appear in the input
    if [[ "$input" == *'\t'* || "$input" == *'\n'* ]]; then
        # Convert literal escape sequences to actual characters using printf
        input=$(printf "%b" "$input")
    fi
    
    # Process with the normal whitespace normalization
    printf '%s' "$input" | tr '\n\r\t' ' ' | sed 's/  */ /g' | sed 's/^ //; s/ $//'
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

# Function to check if character is an emoji
is_emoji() {
    local char="$1"
    # Check if the character is in the Unicode emoji range
    # This is a simple check and may not catch all emojis
    # Modern emojis typically have code points > U+1F000
    
    local code=$(printf '%d' "'$char")
    # Use a more comprehensive approach to detect emojis
    # Check common emoji ranges and specific emoji characters
    # First try the simple test for standard emojis (U+1F000 and above)
    if [[ "$char" =~ $'\U0001F'[0-9A-Fa-f]+ ]] || [[ "$code" -gt 126000 ]]; then
        return 0 # It's a standard emoji
    fi
    
    # Test for specifically known emoji characters that might not be caught by the first check
    case "$char" in
        # Common emojis outside the main emoji block
        "❌"|"⭕"|"✅"|"☑️"|"✔️"|"❗"|"❓"|"⚠️"|"⚡"|"🛠️")
            return 0 # It's an emoji
            ;;
        *)
            # Check for other emoji ranges
            local first_byte=$(printf '%d' "'${char:0:1}")
            if [ "$first_byte" -ge 226 ] && [ "$first_byte" -le 240 ]; then
                # This catches many emojis in the Unicode range U+2600 to U+27BF
                # and some other ranges
                local full_char=$(printf '%x' "'$char" 2>/dev/null)
                if [[ "$full_char" =~ ^"26"|^"27"|^"23"|^"2b"|^"e2" ]]; then
                    return 0 # Likely an emoji
                fi
            fi
            return 1 # Not an emoji
            ;;
    esac
}
