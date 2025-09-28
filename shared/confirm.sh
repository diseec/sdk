#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ CONFIRM FUNCTION - Interactive Yes/No Prompt with Optional Action       ┃
# ┃ Provides a consistent way to ask yes/no questions and handle responses  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

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
    if [ "$D_GLOB_TTY" = "true" ]; then
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
    if [ "$D_GLOB_ENV" = "TESTING" ]; then
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
