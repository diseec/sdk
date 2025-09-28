#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ RETRY FUNCTION - Retry Mechanism with Manual and Automatic Modes        ┃
# ┃ Provides a robust way to retry commands with user prompts or automatic  ┃
# ┃ retries including timeout and max attempts                              ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Retry mechanism function
# Usage: retry [--manual] [--timeout=N] [--max-attempts=N] "complex command" [output_var]
# Options:
#   --manual           Manual retry mode (default): asks user for each retry attempt with no max limit
#   --auto             Automatic retry mode: retries automatically with a timeout between attempts
#   --timeout=N        Auto-retry mode: wait N seconds before retrying automatically (default: 5)
#   --max-attempts=N   Maximum number of automatic retry attempts (default: 3, only applies in auto mode)
#   "complex command" The command to execute (in quotes if it contains spaces or special characters)
#   [output_var]      Optional: Name of variable to store command output
#
# Behavior:
#   - Default: Manual mode (asks user for each retry with no max limit)
#   - With --timeout: Auto-retry mode with specified pause between attempts (limited by max-attempts)
#   - With both --manual and --timeout: First tries auto-retries up to max-attempts, then switches to manual mode
retry() {
    local operation_cmd=""
    local output_var=""
    local max_attempts=3  # Default max attempts for auto mode
    local timeout=5       # Default timeout in seconds for auto mode
    local manual_mode=false
    local auto_mode=false

    # Parse options and arguments
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
                if [ -z "$operation_cmd" ]; then
                    operation_cmd="$1"
                elif [ -z "$output_var" ]; then
                    output_var="$1"
                fi
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
    local cmd_output=""

    # store set -e state
    local set_e_state=$(set +o | grep errexit)
    set +e  # Disable exit on error for retries

    stdout -d --icon="↻" "Starting retry mechanism for command: '$operation_cmd'"

    # First phase: Automatic retries if auto_mode is enabled
    if [ "$auto_mode" = "true" ]; then
        # stdout -l "Auto-retry mode enabled (max $max_attempts attempts, $timeout second intervals)"

        # Set up signal handling for auto mode
        local interrupted=false
        trap 'interrupted=true' INT

        while [ $attempt -le $max_attempts ] && [ "$success" = "false" ] && [ "$interrupted" = "false" ]; do
            # Execute the command and capture output
            cmd_output=$(eval "$operation_cmd" 2>&1)
            exit_code=$?

            if [ $exit_code -eq 0 ]; then
                success=true
                if [ $attempt -gt 1 ]; then
                    stdout -i "Command succeeded on auto-attempt $attempt/$max_attempts '$operation_cmd'"
                fi
            else
                echo $cmd_output  # Show command output on failure

                if [ $attempt -lt $max_attempts ]; then
                    stdout -e "Unable to execute '$operation_cmd'"
                    stdout -w --processing "Retrying in $timeout seconds ($attempt/$max_attempts) Press Ctrl+C to cancel"
                    sleep $timeout &
                    wait $!  # Wait for sleep to complete, but allow signal interruption

                    # Check if we were interrupted during sleep
                    if [ "$interrupted" = "true" ]; then
                        stdout -l "Operation cancelled by user (Ctrl+C)"
                        break
                    fi

                    attempt=$((attempt + 1))
                else
                    # stdout -w "All $max_attempts automatic retries failed."
                    # If manual mode is also enabled, we'll continue to manual phase
                    if [ "$manual_mode" = "true" ]; then
                        stdout -l --processing "Switching to manual retry"
                    fi
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
        attempt=1  # Reset attempt counter for manual mode

        # Set up signal handling for manual mode
        local interrupted=false
        trap 'interrupted=true' INT

        while [ "$success" = "false" ] && [ "$interrupted" = "false" ]; do
            # If this is not the first manual attempt, run the command and capture output
            if [ $attempt -gt 0 ]; then
                # Execute the command and capture output
                cmd_output=$(eval "$operation_cmd" 2>&1)
                exit_code=$?

                if [ $exit_code -eq 0 ]; then
                    success=true
                    break
                else
                    echo $cmd_output  # Show command output on failure
                    stdout -e "Unable to execute '$operation_cmd'"
                fi
            fi

            # Ask for confirmation to retry
            if confirm "Operation failed. Retry? Failure on '$operation_cmd'"; then
                attempt=$((attempt + 1))
            else
                stdout -l "User chose not to retry. Exiting retry loop."
                break
            fi

            # Check if we were interrupted during confirm
            if [ "$interrupted" = "true" ]; then
                stdout -l "Operation cancelled by user (Ctrl+C)"
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

    # Store output in variable if requested
    if [ -n "$output_var" ]; then
        if [ "$output_var" = "output_var" ]; then stdout -e "Variable to store the output cannot be output_var"; fi
        eval "$output_var=\"\$cmd_output\""
    else
        if [ $exit_code -eq 0 ]; then
            echo "$cmd_output"
        fi
    fi

    return $exit_code
}
