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
    local repo_name=${D_REPO_NAME:-$D_CLI_GLOBAL_NAME}
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
        content="Sunshine, rainbows and sh*t!";
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

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ INPUT FUNCTION - Interactive User Input with Validation & Styling       ┃
# ┃ Provides a consistent, user-friendly way to collect input from users     ┃
# ┃ with optional validation, default values, and secure hidden input        ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
input() {
    # BASIC USAGE:
    #   result=$(input "Prompt text:")
    #   Returns user input as a string
    #
    # PARAMETERS:
    #   $1              Required prompt text to display to user
    #   --default=VAL   Default value (shown in gray, used if user presses enter)
    #   --validate=REG  Regex pattern for input validation
    #   --error=MSG     Custom error message for validation failures
    #   --hidden        Hide input (for passwords, no echo to terminal)
    #   --optional      Allow empty input (default: input is required)
    #
    # EXAMPLES:
    #   # Basic required input
    #   name=$(input "Enter your name:")
    #
    #   # Input with default value
    #   port=$(input "Enter port:" --default="3000")
    #   email=$(input "Enter email:" --default="user@example.com")
    #
    #   # Input with validation
    #   age=$(input "Enter age:" --validate="^[0-9]+$" --error="Age must be a number")
    #   ip=$(input "IP address:" --validate="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
    #
    #   # Secure password input (hidden)
    #   password=$(input "Enter password:" --hidden)
    #   token=$(input "API token:" --hidden --validate="^[a-zA-Z0-9]{20,}$")
    #
    #   # Optional input (can be empty)
    #   comment=$(input "Any comments:" --optional)
    #   description=$(input "Description:" --optional --default="No description")
    #
    #   # Complex validation examples
    #   username=$(input "Username:" --validate="^[a-zA-Z0-9_]{3,20}$" \
    #              --error="Username: 3-20 chars, letters/numbers/underscore only")
    #   url=$(input "Website URL:" --validate="^https?://.*" \
    #         --error="URL must start with http:// or https://")
    #
    # FEATURES:
    #   - Consistent styling using logit() and ansi() functions
    #   - Proper signal handling (Ctrl+C safe)
    #   - Input validation with regex patterns
    #   - Default values displayed in gray brackets
    #   - Hidden input mode for sensitive data
    #   - Retry loop for invalid input with clear error messages
    #   - Optional vs required input modes
    #   - Terminal state preservation and restoration
    
    local prompt="$1"; shift
    local default_value=""
    local validate_pattern=""
    local error_message="Invalid input. Please try again."
    local hidden=false
    local required=true
    
    # Parse options
    while [ $# -gt 0 ]; do
        case "$1" in
            --default=*)
                default_value="${1#*=}"
                required=false
                shift
                ;;
            --validate=*)
                validate_pattern="${1#*=}"
                shift
                ;;
            --error=*)
                error_message="${1#*=}"
                shift
                ;;
            --hidden)
                hidden=true
                shift
                ;;
            --optional)
                required=false
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Store original terminal settings
    local old_settings=$(stty -g)
    trap 'stty "$old_settings"; echo ""; return 1' INT TERM
    
    while true; do
        # Display prompt
        local display_prompt="$prompt"
        if [ -n "$default_value" ]; then
            display_prompt="$prompt [$(ansi 90 "$default_value")]"
        fi
        
        printf "$(logit --ansi="34" --icon=">" "$display_prompt") "
        
        # Read input
        local user_input=""
        if [ "$hidden" = true ]; then
            # Hidden input (like password)
            stty -echo
            read user_input
            stty echo
            printf "\n"
        else
            # Normal input
            read user_input
        fi
        
        # Use default if input is empty and default exists
        if [ -z "$user_input" ] && [ -n "$default_value" ]; then
            user_input="$default_value"
        fi
        
        # Check if input is required
        if [ "$required" = true ] && [ -z "$user_input" ]; then
            logit -e "Input is required."
            continue
        fi
        
        # Validate input if pattern provided
        if [ -n "$validate_pattern" ] && [ -n "$user_input" ]; then
            if ! echo "$user_input" | grep -qE "$validate_pattern"; then
                logit -e "$error_message"
                continue
            fi
        fi
        
        # Input is valid, break the loop
        break
    done
    
    # Restore terminal settings
    stty "$old_settings"
    trap - INT TERM
    
    # Return the input
    echo "$user_input"
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
    printf "\e[47m    $(capitalize $D_ORG_NAME) DevOps CLI \e[0m\e[1m\e[34m Automation Toolkit \e[0m\e[97mv$D_VERSION\n\e[0m"
    printf "\n"
    printf "\e[90mThis software and associated documentation files\n(the \"Software\") are the  exclusive property  of\n$(capitalize $D_ORG_NAME) L.T.E. and are protected by copyright and\nother intellectual property laws.\nPermission is hereby granted, free of charge, to\nany person obtaining a copy of this Software, to\nse the Software within the organization only.\n\e[0m"
    printf "\n"
    printf "\e[90m\e[1mWebsite  \e[0m\e[90m    https://$D_ORG_NAME.com\n\e[0m"
    printf "\e[90m\e[1mGitHub   \e[0m\e[90m    https://github.com/$D_ORG_NAME\n\e[0m"
    printf "\e[90m\e[1mLinkedIn \e[0m\e[90m    https://linkedin.com/company/$D_ORG_NAME\n\e[0m"
    printf "\n"
    printf "\e[90mCopyright (c) 2018 $(capitalize $D_ORG_NAME),  all rights  reserved\n\e[0m"
    printf "\n"
}