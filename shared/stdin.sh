#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ INPUT FUNCTION - Interactive User Input with Validation & Styling       ┃
# ┃ Provides a consistent, user-friendly way to collect input from users    ┃
# ┃ with optional validation, default values, and secure hidden input       ┃
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

    stdout -q --ansi="35" --icon=">" "$display_prompt"
    
    # Check if input is available from redirection (<, <<, <<<, pipe)
    if [ ! -t 0 ] && [ "$D_GLOB_TTY" = "false" ]; then
        # Non-TTY mode with redirection available
        if [ "$hidden" = true ]; then
            # For hidden input, just read once
            IFS= read -r user_input
        else
            # For normal input, read as usual
            read user_input
        fi
    elif [ "$D_GLOB_TTY" = "true" ]; then
        # TTY mode
        # Store original terminal settings
        local old_settings=$(stty -g)
        trap 'stty "$old_settings"; echo "" >&2; return 1' INT TERM
        
        # Read input with appropriate method
        if [ "$hidden" = true ]; then
            # Hidden input (like password) with asterisk feedback
            user_input=""
            while true; do
                # Read a single character
                IFS= read -r -s -n 1 char
                
                # Exit on EOF or interrupt (ctrl+d or ctrl+c)
                if [[ -z "$char" ]]; then
                    echo >&2
                    break
                fi
                
                # Break on Enter key (newline or carriage return)
                if [[ "$char" == $'\n' || "$char" == $'\r' ]]; then
                    echo >&2
                    break
                # Handle backspace (ASCII 127) or delete
                elif [[ "$char" == $'\177' || "$char" == $'\b' ]]; then
                    if [ ${#user_input} -gt 0 ]; then
                        user_input="${user_input%?}"
                        printf "\b \b" >&2
                    fi
                else
                    user_input+="$char"
                    printf "*" >&2
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
    
    printf "\n" >&2
    
    # In testing environments, echo the input for visibility
    stdout -d --icon="<" "Input received (non-TTY mode): $user_input"

    # Use default if input is empty and default exists
    if [ -z "$user_input" ] && [ -n "$default_value" ]; then
        user_input="$default_value"
    fi
    
    # Check if input is required
    if [ "$required" = true ] && [ -z "$user_input" ]; then
        if [ "$D_GLOB_TTY" = "true" ]; then
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
            if [ "$D_GLOB_TTY" = "true" ]; then
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
    
    stdout -d --icon="<" "Input received (non-TTY mode) (Processed): $user_input"

    # Set the value to the provided variable name
    eval "$var_name=\"$user_input\""
}
