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

# Usage: stdout [type] [--icon=ICON] [--ansi=CODE] [--level=LEVEL] "Your message here"
# Types: -l|--log (default), -d|--debug, -f|--fail, -e|--error, -o|--okey, -w|--warning, -i|--info, -q|--question, -a|--ai, -s|--statement
# Examples:
#   stdout "This is a log message"
#   stdout -i --icon="i" --ansi="34" "This is an info message"
#   stdout --icon="✓" --ansi="32" "This is a success message"
#   stdout -e "This is an error message"
#   stdout -w --icon="!" "This is a warning message"
#   stdout -d --icon="¤" "This is a debug message"
#   stdout -f --icon="✖" "This is a failure message"
#   stdout -q --icon="?" "This is a question message"
#   stdout -a --icon="✦" "This is an AI-related message"
#   stdout -s "This is a plain statement message"
stdout() {
    local repo_name=${D_REPO_NAME:-$D_CLI_GLOBAL_NAME}
    local type="--log"
    local default_level="VERBOSE"
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
            --level=*)
                local given_level="${1#*=}"
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
        -l|--log)       default_ansi="90"; default_icon="";  default_level="VERBOSE" ;;
        -d|--debug)     default_ansi="31"; default_icon="¤"; default_level="VERBOSE" ;;
        -f|--fail)      default_ansi="31"; default_icon="✖"; default_level="ERROR"   ;; # ✗
        -e|--error)     default_ansi="31"; default_icon="E"; default_level="ERROR"   ;;
        -o|--okey)      default_ansi="32"; default_icon="✓"; default_level="INFO"    ;; # ✔
        -w|--warning)   default_ansi="33"; default_icon="!"; default_level="WARNING" ;;
        -i|--info)      default_ansi="34"; default_icon="i"; default_level="INFO"    ;;
        -q|--question)  default_ansi="35"; default_icon="?"; default_level="ERROR"    ;;
        -a|--ai)        default_ansi="96"; default_icon="✦"; default_level="INFO"    ;;
        -s|--statement) default_ansi="97"; default_icon="";  default_level="INFO"    ;;
        *)                                                   default_level="VERBOSE" ;;
    esac

    # Prepare icon and ANSI color and level
    local _ansi="${given_ansi:-$default_ansi}"
    local _icon="${given_icon:-$default_icon}"
    local _level="${given_level:-$default_level}"

    # Prepare prompt & content
    local prompt="[$(date "+%H:%M:%S")][$(capitalize "$repo_name")]"
    prompt="$(ansi 90 "$prompt")"
    if [ -n "$_icon" ]; then prompt="$prompt$(ansi $_ansi "[$_icon]")"; fi

    # Only colorize content if it's not empty
    if [ -n "$content" ]; then
        content="$(ansi 90 "$content")"
    fi

    # Handle logging levels
    case $D_GLOBAL_LOG_LEVEL in
        VERBOSE|verbose) ;;
        INFO|info) case $_level in       VERBOSE) return 0; esac ;;
        WARNING|warning) case $_level in VERBOSE|INFO) return 0; esac ;;
        ERROR|error) case $_level in     VERBOSE|INFO|WARNING) return 0; esac ;;
        QUIET|quiet) case $_level in     VERBOSE|INFO|WARNING|ERROR) return 0; esac ;;
    esac

    # Output log message
    printf "%s %b\n" "$prompt" "$content"
}

# Function for use in if statements - returns 0 (true) or 1 (false)
# usage:
# if confirm "Do you want to proceed?"; then
#     # Your code here for the "yes" case
# else
#     # Your code here for the "no" case
# fi
# OR
# confirm "Do you want to proceed?" echo 'does this!'
confirm() {
    local question=$1; shift
    
    # First output the question so in non-tty environments it's still shown
    printf "$(stdout -q --ansi="35" --icon="Y/N" "$question ")"

    # Check if TTY is available
    if [ "$D_GLOBAL_TTY_AVAILABLE" = "true" ]; then
        # Store original terminal settings to restore later
        local old_settings=$(stty -g)
    
        # Enable proper signal handling (especially Ctrl+C)
        trap 'stty "$old_settings"; echo ""; return 1' INT TERM
    
        # Read a single character, but allow signal handling
        stty -echo -icanon
        local response=$(head -c1)
    
        # Restore terminal settings
        stty "$old_settings"
        trap - INT TERM
    else
        # Non-TTY mode: Try to use redirected input if available
        if [ -t 0 ] || [ -p /dev/stdin ]; then
            # Use read instead of head -c1 to read the full line but only use first character
            # This properly consumes the newline that follows
            local full_line
            read full_line
            local response=${full_line:0:1}
        else
            # Default to no in fully automated environments with no input
            local response="n"
        fi
    fi
    
    printf "\n"
    
    # In testing environments, echo the input for visibility
    if [ "$D_GLOBAL_ENV" = "TESTING" ]; then
        stdout -i --icon="<" "Input received (non-TTY mode): $response"
    fi

    case "$response" in
        [yY][eE][sS]|[yY])
            if [ $# -gt 0 ]; then "$@"; fi
            return 0
            ;; # Return 0 for success/true in bash
        [nN][oO]|[nN]) return 1 ;; # Return 1 for failure/false in bash
        *)
            # Invalid response, prompt again
            stdout -e "Invalid response. Please enter Y or N."
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
# BASIC USAGE:
#   stdin variable "Prompt text:"
#   Sets the variable with the user's input
#
# PARAMETERS:
#   $1              Variable name to store the input
#   $2              Required prompt text to display to user
#   --default=VAL   Default value (shown in gray, used if user presses enter)
#   --validate=REG  Regex pattern for input validation
#   --error=MSG     Custom error message for validation failures
#   --hidden        Hide input (for passwords, no echo to terminal)
#   --optional      Allow empty input (default: input is required)
#
# EXAMPLES:
#   # Basic required input
#   stdin name "Enter your name:"
#
#   # Input with default value
#   stdin port "Enter port:" --default="3000"
#   stdin email "Enter email:" --default="user@example.com"
#
#   # Input with validation
#   stdin age "Enter age:" --validate="^[0-9]+$" --error="Age must be a number"
#   stdin ip "IP address:" --validate="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
#
#   # Secure password input (hidden)
#   stdin password "Enter password:" --hidden
#   stdin token "API token:" --hidden --validate="^[a-zA-Z0-9]{20,}$"
#
#   # Optional input (can be empty)
#   stdin comment "Any comments:" --optional
#   stdin description "Description:" --optional --default="No description"
#
#   # Complex validation examples
#   stdin username "Username:" --validate="^[a-zA-Z0-9_]{3,20}$" \
#          --error="Username: 3-20 chars, letters/numbers/underscore only"
#   stdin url "Website URL:" --validate="^https?://.*" \
#         --error="URL must start with http:// or https://"
#
# FEATURES:
#   - Consistent styling using stdout() and ansi() functions
#   - Proper signal handling (Ctrl+C safe)
#   - Input validation with regex patterns
#   - Default values displayed in gray brackets
#   - Hidden input mode for sensitive data
#   - Retry loop for invalid input with clear error messages
#   - Optional vs required input modes
#   - Terminal state preservation and restoration
stdin() {
    local var_name="$1"; shift
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
    
    # Display prompt first so in non-tty environments it's still shown
    local display_prompt=""
    if [ -n "$prompt" ]; then
        display_prompt="$prompt"
    fi
    if [ -n "$default_value" ]; then
        local default_prompt="$(ansi "2;90" "(default: $default_value)")"
        if [ -n "$display_prompt" ]; then
            display_prompt="$display_prompt $default_prompt"
        else
            display_prompt="$default_prompt"
        fi
    fi

    printf "$(stdout -q --ansi="35" --icon=">" "$display_prompt") "
    
    # Check if input is available from redirection (<, <<, <<<, pipe)
    if [ ! -t 0 ] && [ "$D_GLOBAL_TTY_AVAILABLE" = "false" ]; then
        # Non-TTY mode with redirection available
        if [ "$hidden" = true ]; then
            # For hidden input, just read once
            IFS= read -r user_input
        else
            # For normal input, read as usual
            read user_input
        fi
    elif [ "$D_GLOBAL_TTY_AVAILABLE" = "true" ]; then
        # TTY mode
        # Store original terminal settings
        local old_settings=$(stty -g)
        trap 'stty "$old_settings"; echo ""; return 1' INT TERM
        
        # Read input with appropriate method
        if [ "$hidden" = true ]; then
            # Hidden input (like password) with asterisk feedback
            user_input=""
            while true; do
                # Read a single character
                IFS= read -r -s -n 1 char
                
                # Exit on EOF or interrupt (ctrl+d or ctrl+c)
                if [[ -z "$char" ]]; then
                    echo
                    break
                fi
                
                # Break on Enter key (newline or carriage return)
                if [[ "$char" == $'\n' || "$char" == $'\r' ]]; then
                    echo
                    break
                # Handle backspace (ASCII 127) or delete
                elif [[ "$char" == $'\177' || "$char" == $'\b' ]]; then
                    if [ ${#user_input} -gt 0 ]; then
                        user_input="${user_input%?}"
                        printf "\b \b"
                    fi
                else
                    user_input+="$char"
                    printf "*"
                fi
            done
        else
            # Normal input
            read user_input
        fi
        
        # Restore terminal settings
        stty "$old_settings"
        trap - INT TERM
    else
        # No TTY available and no redirection - use default value if available
        if [ -n "$default_value" ]; then
            user_input="$default_value"
        else
            # For testing environments with no input
            user_input=""
        fi
    fi
    
    printf "\n"
    
    # In testing environments, echo the input for visibility
    if [ "$D_GLOBAL_ENV" = "TESTING" ]; then
        stdout -i --icon="<" "Input received (non-TTY mode): $user_input"
    fi

    # Use default if input is empty and default exists
    if [ -z "$user_input" ] && [ -n "$default_value" ]; then
        user_input="$default_value"
    fi
    
    # Check if input is required
    if [ "$required" = true ] && [ -z "$user_input" ]; then
        if [ "$D_GLOBAL_TTY_AVAILABLE" = "true" ]; then
            stdout -e "Input is required."
            # Retry stdin in TTY mode
            stdin "$var_name" "$prompt" ${default_value:+--default="$default_value"} ${validate_pattern:+--validate="$validate_pattern"} ${error_message:+--error="$error_message"} ${hidden:+--hidden} ${required:+--required}
            return $?
        else
            # In non-TTY mode, fail or use a sensible fallback
            stdout -e "Required input missing and no TTY available."
            user_input="__MISSING_REQUIRED_INPUT__"
        fi
    fi
    
    # Validate input if pattern provided
    if [ -n "$validate_pattern" ] && [ -n "$user_input" ]; then
        if ! echo "$user_input" | grep -qE "$validate_pattern"; then
            if [ "$D_GLOBAL_TTY_AVAILABLE" = "true" ]; then
                stdout -e "$error_message"
                # Retry input in TTY mode
                stdin "$var_name" "$prompt" ${default_value:+--default="$default_value"} ${validate_pattern:+--validate="$validate_pattern"} ${error_message:+--error="$error_message"} ${hidden:+--hidden} ${required:+--required}
                return $?
            else
                # In non-TTY mode, use default or fail
                stdout -e "Input validation failed and no TTY available."
                if [ -n "$default_value" ]; then
                    user_input="$default_value"
                else
                    user_input="__INVALID_INPUT__"
                fi
            fi
        fi
    fi
    
    # In testing environments, echo the input for visibility
    if [ "$D_GLOBAL_ENV" = "TESTING" ]; then
        stdout -i --icon="<" "Input received (non-TTY mode) (Processed): $user_input"
    fi

    # Set the value to the provided variable name
    eval "$var_name=\"$user_input\""
}


# Retry mechanism function
# Usage: retry [--manual] [--timeout=N] [--max-attempts=N] "complex command"
# Options:
#   --manual           Manual retry mode (default): asks user for each retry attempt with no max limit
#   --auto             Automatic retry mode: retries automatically with a timeout between attempts
#   --timeout=N        Auto-retry mode: wait N seconds before retrying automatically (default: 5)
#   --max-attempts=N   Maximum number of automatic retry attempts (default: 3, only applies in auto mode)
#
# Behavior:
#   - Default: Manual mode (asks user for each retry with no max limit)
#   - With --timeout: Auto-retry mode with specified pause between attempts (limited by max-attempts)
#   - With both --manual and --timeout: First tries auto-retries up to max-attempts, then switches to manual mode
retry() {
    local operation_cmd=""
    local max_attempts=3  # Default max attempts for auto mode
    local timeout=5       # Default timeout in seconds for auto mode
    local manual_mode=false
    local auto_mode=false
    
    # Parse options
    while [ $# -gt 0 ]; do
        case "$1" in
            --manual)
                manual_mode=true
                shift
                ;;
            --auto)
                auto_mode=true
                shift
                ;;
            --timeout=*)
                timeout="${1#*=}"
                shift
                ;;
            --max-attempts=*)
                max_attempts="${1#*=}"
                shift
                ;;
            *)
                # The only non-option argument is the command
                operation_cmd="$1"
                shift
                ;;
        esac
    done

    # If no mode specified, default to manual
    if [ "$auto_mode" = "false" ] && [ "$manual_mode" = "false" ]; then
        manual_mode=true
    fi
    
    local attempt=1
    local success=false
    local exit_code=1  # Default to failure
    
    # store set -e state
    local set_e_state=$(set +o | grep errexit)
    set +e  # Disable exit on error for retries

    # First phase: Automatic retries if auto_mode is enabled
    if [ "$auto_mode" = "true" ]; then
        # stdout -l "Auto-retry mode enabled (max $max_attempts attempts, $timeout second intervals)"
        
        # Set up signal handling for auto mode
        local interrupted=false
        trap 'interrupted=true' INT
        
        while [ $attempt -le $max_attempts ] && [ "$success" = "false" ] && [ "$interrupted" = "false" ]; do
            # Execute the command
            eval "$operation_cmd"
            exit_code=$?
            
            if [ $exit_code -eq 0 ]; then
                success=true
                # stdout -o "Command succeeded on auto-attempt $attempt/$max_attempts"
            else
                if [ $attempt -lt $max_attempts ]; then
                    stdout -w "Operation failed. Retrying in $timeout seconds... ($attempt/$max_attempts) Press Ctrl+C to cancel"
                    sleep $timeout &
                    wait $!  # Wait for sleep to complete, but allow signal interruption
                    
                    # Check if we were interrupted during sleep
                    if [ "$interrupted" = "true" ]; then
                        # stdout -w "Operation cancelled by user (Ctrl+C)"
                        break
                    fi
                    
                    attempt=$((attempt + 1))
                else
                    # # stdout -w "All $max_attempts automatic retries failed."
                    # # If manual mode is also enabled, we'll continue to manual phase
                    # if [ "$manual_mode" = "true" ]; then
                    #     stdout -i "Switching to manual retry..."
                    # fi
                    break
                fi
            fi
        done
        
        # Reset interrupted flag for potential manual phase
        interrupted=false
        trap - INT
    fi
    
    # Second phase: Manual retries if manual_mode is enabled and command hasn't succeeded yet
    if [ "$manual_mode" = "true" ] && [ "$success" = "false" ]; then
        # stdout -l "Manual retry mode active (unlimited attempts, user confirmation required)"
        attempt=1  # Reset attempt counter for manual mode
        
        # Set up signal handling for manual mode
        local interrupted=false
        trap 'interrupted=true' INT
        
        while [ "$success" = "false" ] && [ "$interrupted" = "false" ]; do
            # If this is not the first manual attempt, run the command
            if [ $attempt -gt 0 ]; then
                eval "$operation_cmd"
                exit_code=$?
                
                if [ $exit_code -eq 0 ]; then
                    success=true
                    # stdout -o "Command succeeded on manual attempt $attempt"
                    break
                fi
            fi
            
            # Ask for confirmation to retry
            if confirm "Operation failed. Retry?"; then
                attempt=$((attempt + 1))
            else
                # stdout -w "User chose not to retry. Exiting retry loop."
                break
            fi
            
            # Check if we were interrupted during confirm
            if [ "$interrupted" = "true" ]; then
                # stdout -w "Operation cancelled by user (Ctrl+C)"
                break
            fi
        done
        
        # Restore default signal handling
        trap - INT
    fi

    # restore set -e state
    if [[ "$set_e_state" == *"on"* ]]; then
        set -e
    fi
    
    return $exit_code
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
