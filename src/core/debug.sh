#!/bin/bash

# Set debug variables early
: "${D_LOG_LEVEL:=INFO}"  # DEBUG, INFO, WARNING, ERROR
: "${DEBUG:=false}"
: "${D_TRACE_DEPTH:=10}"  # How many stack frames to show (max)
: "${D_TRACE_ENABLED:=true}"  # Enable/disable tracing

# Original X function - preserved (using logit as requested)
X() {
    local file="${BASH_SOURCE[1]##*/}"
    local line="${BASH_LINENO[0]:-0}"
    local func="${FUNCNAME[1]:-unknown}"
    
    if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
        # Log entry to function with more context
        logit -e --icon="¤][$file:$line:$func" "$*"
    fi
}

# Trace function call stack and return a formatted stack trace
get_stack_trace() {
    local depth=${1:-$D_TRACE_DEPTH}
    local i=0
    local stack_trace=""
    local frame_count=${#FUNCNAME[@]}
    local max_depth=$((frame_count < depth ? frame_count : depth))
    
    # Skip first frame (the get_stack_trace function itself)
    for ((i=1; i<max_depth; i++)); do
        local func="${FUNCNAME[$i]:-main}"
        local file="${BASH_SOURCE[$i]:-unknown_source}"
        local line="${BASH_LINENO[$((i-1))]:-0}"
        local cmd="${BASH_COMMAND:-unknown_command}"
        
        # Format the file path to be more readable - show relative path if possible
        if [[ -n "$SDK_DIR" && "$file" == "$SDK_DIR"* ]]; then
            file="sdk${file#$SDK_DIR}"
        fi
        
        # Add trace line with better formatting - highlight function name
        stack_trace+=$(printf "  \033[97m%-25s\033[0m %s:\033[97m%-3s\033[0m\n" "$func()" "$file" "$line")
        
        # For the first frame, also show the command that failed
        if [[ $i -eq 1 ]]; then
            stack_trace+=$(printf "    \033[31m→\033[0m \033[90mCommand:\033[0m %s\n" "$cmd")
        fi
    done
    
    # If there are more frames than we showed
    if [[ $frame_count -gt $max_depth ]]; then
        stack_trace+=$(printf "  \033[90m... and %d more frames\033[0m\n" $((frame_count - max_depth)))
    fi
    
    echo -e "$stack_trace"
}

# Error handler function
trace_error_handler() {
    local err_code=$?
    
    # Temporarily disable error trapping to avoid recursive traps
    trap - ERR
    
    # Disable error exit in case any of our error handling commands fail
    set +e
    
    # Get the context of the error
    local cmd="${BASH_COMMAND:-unknown_command}"
    local func="${FUNCNAME[1]:-main}"
    local file="${BASH_SOURCE[1]:-unknown_source}"
    local line="${BASH_LINENO[0]:-0}"
    
    # Get timestamp
    local timestamp=$(date "+%H:%M:%S")
    local repo_name=${REPO_NAME:-d}
    
    # Print error header with project's style and important info combined
    printf "\n"
    printf "\033[90m[%s]\033[0m\033[31m[E]\033[0m in \033[97m%s()\033[0m at \033[90m%s:%s\033[0m \033[90m|\033[0m \033[31mExit %d\033[0m\n" "$timestamp" "$func" "$file" "$line" "$err_code"
    printf "\033[97m-------------------------------------------------------------------------------\033[0m\n"
    
    # Show failed command
    printf "\033[90mCommand: \033[31m%s\033[0m\n" "$cmd"
    
    # Print stack trace with better formatting
    printf "\n\033[1;90mSTACK TRACE\033[0m\033[90m %s\033[0m\n" "$(printf '%*s' 60 | tr ' ' '-')"
    local trace=$(get_stack_trace)
    echo -e "$trace"
    
    # Print better-organized system info
    printf "\n\033[1;90mSYSTEM INFO\033[0m\033[90m %s\033[0m\n" "$(printf '%*s' 60 | tr ' ' '-')"
    printf "\033[90mBash Version: \033[0m \033[97m%s\033[0m\n" "$BASH_VERSION"
    printf "\033[90mSDK_DIR:      \033[0m \033[97m%s\033[0m\n" "${SDK_DIR:-unknown}"
    printf "\033[90mWORK_DIR:     \033[0m \033[97m%s\033[0m\n" "${WORK_DIR:-unknown}"
    printf "\n"
    
    # Reset trap
    if [[ "$D_TRACE_ENABLED" == "true" ]]; then
        trap trace_error_handler ERR
    fi
    
    # By default, don't exit unless explicitly configured to do so
    if [[ "${D_EXIT_ON_ERROR:-true}" == "true" ]]; then
        exit $err_code
    fi
}

# Start tracing - can be called explicitly or will be called by src_cor_debug_init
start_tracing() {
    if [[ "$D_TRACE_ENABLED" == "true" ]]; then
        trap trace_error_handler ERR
    fi
}

# Stop tracing - disable the error trap
stop_tracing() {
    trap - ERR
}

# Function to extract variables from the calling environment
capture_environment_state() {
    local output=""
    
    # List common environment variables for debugging
    local vars_to_capture=(
        "PWD" "OLDPWD" "HOME" "USER" "HOSTNAME" "PATH"
        "SDK_DIR" "SDK_SRC_DIR" "WORK_DIR" "D_LOG_LEVEL" "DEBUG"
    )
    
    for var in "${vars_to_capture[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            output+="$var=${!var}\n"
        fi
    done
    
    # Add any D_ prefixed variables that weren't in our predefined list
    for var in $(env | grep -E '^D_' | cut -d= -f1); do
        if ! [[ " ${vars_to_capture[*]} " =~ " ${var} " ]]; then
            output+="$var=${!var:-unset}\n"
        fi
    done
    
    echo -e "$output"
}

function src_cor_debug_init() {
    # Set default values for potentially unbound variables
    : "${D_LOG_LEVEL:=INFO}"
    : "${DEBUG:=false}"
    : "${D_EXIT_ON_ERROR:=true}"
    
    # Always exit on error unless configured otherwise
    if [[ "${D_EXIT_ON_ERROR}" == "true" ]]; then
        set -e
    fi
    
    # Handle undefined variables
    set -u
    
    # Start the tracing system
    start_tracing
    
    # Utility functions for toggling behavior
    function enable_error_exit() {
        set -e
        : "${D_EXIT_ON_ERROR:=true}"
    }
    
    function disable_error_exit() {
        set +e
        : "${D_EXIT_ON_ERROR:=false}"
    }
    
    function enable_strict_vars() {
        set -u
    }
    
    function disable_strict_vars() {
        set +u
    }
    
    # Utility functions for debugging
    
    # Print a visual separator for log output
    function debug_separator() {
        local title="${1:-}"
        local char="${2:-=}"
        local width=${3:-50}
        
        if [[ -n "$title" ]]; then
            printf "\n\033[90m--- %s %s\033[0m\n" "$title" "$(printf '%*s' $((width - ${#title} - 5)) | tr ' ' "$char")"
        else
            printf "\n\033[90m%s\033[0m\n" "$(printf '%*s' $width | tr ' ' "$char")"
        fi
    }
    
    # Print a function's arguments for debugging
    function debug_args() {
        local func_name="${FUNCNAME[1]:-unknown}"
        
        if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
            debug_separator "DEBUG: FUNCTION ARGUMENTS" "-"
            printf "\033[90mFunction:   \033[0m \033[97m%s\033[0m\n" "$func_name"
            printf "\033[90mArguments:  \033[0m \033[97m%d\033[0m\n" "$#"
            
            if [ $# -gt 0 ]; then
                for i in $(seq 1 $#); do
                    printf "  \033[90m[%d]\033[0m %s\n" "$i" "${!i}"
                done
            else
                printf "  \033[90m(no arguments)\033[0m\n"
            fi
        fi
    }
    
    # Print call stack at any point (not just on error)
    function debug_stack() {
        if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
            debug_separator "DEBUG: CALL STACK" "-"
            local trace=$(get_stack_trace)
            echo -e "$trace"
        fi
    }
    
    # Print all variables in scope with a given prefix
    function debug_vars() {
        local prefix="${1:-D_}"
        local vars=$(compgen -v "$prefix" 2>/dev/null)
        
        if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
            debug_separator "DEBUG: VARIABLES ($prefix*)" "-"
            
            if [ -z "$vars" ]; then
                printf "  \033[90m(no variables with prefix '%s')\033[0m\n" "$prefix"
            else
                local count=0
                for var in $vars; do
                    printf "  \033[97m%-25s\033[0m = %s\n" "$var" "${!var}"
                done
            fi
        fi
    }
    
    # Function to benchmark execution time of commands
    function debug_time() {
        if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
            debug_separator "DEBUG: BENCHMARK" "-"
            printf "\033[90mCommand:    \033[0m %s\n" "$*"
            printf "\033[90mStarted:    \033[0m %s\n" "$(date "+%H:%M:%S")"
        fi
        
        local start_time=$(date +%s.%N)
        "$@"  # Execute the command
        local status=$?
        local end_time=$(date +%s.%N)
        local elapsed=$(echo "$end_time - $start_time" | bc)
        
        if [[ "${D_LOG_LEVEL}" == "DEBUG" || "${DEBUG}" == "true" ]]; then
            printf "\033[90mCompleted:  \033[0m %s\n" "$(date "+%H:%M:%S")"
            printf "\033[90mDuration:   \033[0m \033[97m%.4f\033[0m seconds\n" "$elapsed"
            if [ $status -eq 0 ]; then
                printf "\033[90mExit Code:  \033[0m \033[97m%d\033[0m (success)\n" "$status"
            else
                printf "\033[90mExit Code:  \033[0m \033[31m%d\033[0m (error)\n" "$status"
            fi
        fi
        
        return $status
    }
}
