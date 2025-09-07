#!/bin/bash

# Set debug variables early
: "${D_LOG_LEVEL:=INFO}"  # DEBUG, INFO, WARNING, ERROR
: "${DEBUG:=false}"
: "${D_TRACE_DEPTH:=10}"  # How many stack frames to show (max)
: "${D_TRACE_ENABLED:=true}"  # Enable/disable tracing

# Original x function - preserved (using logit as requested)
x() {
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
    local frame_count=${#FUNCNAME[@]}
    local max_depth=$((frame_count < depth ? frame_count : depth))
    
    # Skip first frame (the get_stack_trace function itself)
    for ((i=1; i<max_depth; i++)); do
        local func="${FUNCNAME[$i]:-main}"
        local file="${BASH_SOURCE[$i]:-unknown_source}"
        local line="${BASH_LINENO[$((i-1))]:-0}"
        local cmd="${BASH_COMMAND:-unknown_command}"
        
        # Format the file path to be more readable - show relative path if possible
        if [[ -n "$D_SDK_DIR" && "$file" == "$D_SDK_DIR"* ]]; then
            file="sdk${file#$D_SDK_DIR}"
        fi
        
        # Print each frame directly instead of building a string
        printf "  \033[97m%-25s\033[0m %s:\033[97m%-3s\033[0m\n" "$func()" "$file" "$line"
        
        # For the first frame, also show the command that failed
        if [[ $i -eq 1 ]]; then
            printf "    \033[31m→\033[0m\033[0m %s\n" "$cmd"
        fi
    done
    
    # If there are more frames than we showed
    if [[ $frame_count -gt $max_depth ]]; then
        printf "  \033[90m... and %d more frames\033[0m\n" $((frame_count - max_depth))
    fi
}

# Function to get and display system information
get_system_info() {
    printf "\n\033[1;90mSYSTEM INFO\033[0m\033[90m %s\033[0m\n" "$(printf '%*s' 60 | tr ' ' '-')"

    # OS info (works on macOS, Linux, and many Unix variants)
    if command -v uname &> /dev/null; then
        os_info="$(uname -s)"
        if [[ "$os_info" == "Darwin" ]]; then
            # macOS specific
            os_version="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
            printf "\033[90mOS            \033[0m \033[90m%s %s\033[0m\n" "macOS" "$os_version"
        elif [[ "$os_info" == "Linux" ]]; then
            # Try to get Linux distro info
            if [ -f /etc/os-release ]; then
                os_name="$(. /etc/os-release && echo "$NAME")"
                os_version="$(. /etc/os-release && echo "$VERSION_ID")"
                printf "\033[90mOS            \033[0m \033[90m%s %s\033[0m\n" "$os_name" "$os_version"
            else
                printf "\033[90mOS            \033[0m \033[90m%s\033[0m\n" "Linux"
            fi
        else
            printf "\033[90mOS            \033[0m \033[90m%s\033[0m\n" "$os_info"
        fi
    fi
    
    printf "\033[90mSDK Version   \033[0m \033[90m%s\033[0m\n" "$D_VERSIONONON"
    printf "\033[90mBash Version  \033[0m \033[90m%s\033[0m\n" "$BASH_VERSION"

    # Docker version (get only the version number)
    if command -v docker &> /dev/null; then
        docker_version="$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//')"
        printf "\033[90mDocker Version\033[0m \033[90m%s\033[0m\n" "$docker_version"
    else
        printf "\033[90mDocker Version\033[0m \033[90m%s\033[0m\n" "not installed"
    fi
    
    # npm version
    if command -v npm &> /dev/null; then
        npm_version="$(npm --version 2>/dev/null || echo 'unknown')"
        printf "\033[90mNPM Version   \033[0m \033[90m%s\033[0m\n" "$npm_version"
    else
        printf "\033[90mNPM Version   \033[0m \033[90m%s\033[0m\n" "not installed"
    fi
    
    # Node.js version
    if command -v node &> /dev/null; then
        node_version="$(node --version 2>/dev/null | sed 's/^v//' || echo 'unknown')"
        printf "\033[90mNode Version  \033[0m \033[90m%s\033[0m\n" "$node_version"
    else
        printf "\033[90mNode Version  \033[0m \033[90m%s\033[0m\n" "not installed"
    fi
}

# Function to display environment variables
get_env_variables() {
    printf "\n\033[1;90mENV VARIABLES\033[0m\033[90m %s\033[0m\n" "$(printf '%*s' 58 | tr ' ' '-')"
    printf "\033[90mPWD            \033[0m \033[90m%s\033[0m\n" "${PWD:-unknown}"
    printf "\033[90mD_INI_PWD      \033[0m \033[90m%s\033[0m\n" "${D_INI_PWD:-unknown}"
    printf "\033[90mD_INI_ARGS     \033[0m \033[90m%s\033[0m\n" "${D_INI_ARGS:-unknown}"
    printf "\033[90mD_LOG_LEVEL    \033[0m \033[90m%s\033[0m\n" "${D_LOG_LEVEL:-unknown}"
    printf "\033[90mD_SDK_DIR      \033[0m \033[90m%s\033[0m\n" "${D_SDK_DIR:-unknown}"
    printf "\033[90mD_CTX_DIR      \033[0m \033[90m%s\033[0m\n" "${D_CTX_DIR:-unknown}"
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
    local repo_name=${D_REPO_NAME:-d}
    
    # Print error header with project's style and important info combined
    printf "\n"
    printf "\033[90m[%s]\033[0m\033[31m[E]\033[0m in \033[97m%s()\033[0m at \033[90m%s:%s\033[0m \033[90m|\033[0m \033[31mExit %d\033[0m\n" "$timestamp" "$func" "$file" "$line" "$err_code"
    printf "\033[97m-------------------------------------------------------------------------------\033[0m\n"
    
    # Show failed command
    printf "\033[31m%s\033[0m\n" "$cmd"
    
    # Print stack trace with better formatting
    printf "\n\033[1;90mSTACK TRACE\033[0m\033[90m %s\033[0m\n" "$(printf '%*s' 60 | tr ' ' '-')"
    # Call get_stack_trace and immediately echo its output (avoid storing in variable)
    get_stack_trace
    
    # Display environment variables and system information using the new functions
    get_env_variables
    get_system_info
    printf "\033[31m-------------------------------------------------------------------------------\033[0m\n"
    printf "\n"
    
    # Always exit with error code (original or 1 if it was 0)
    local exit_code=$err_code
    if [[ $exit_code -eq 0 ]]; then
        exit_code=1
    fi
    
    exit $exit_code
}

# Start tracing - can be called explicitly or will be called by sdk_boo_debug_init
start_tracing() {
    if [[ "$D_TRACE_ENABLED" == "true" ]]; then
        trap trace_error_handler ERR
    fi
}

function sdk_boo_debug_init() {
    # Set default values for potentially unbound variables
    : "${D_LOG_LEVEL:=INFO}"
    : "${DEBUG:=false}"
    : "${D_EXIT_ON_ERROR:=true}"  # This is now enforced regardless
    
    # Always exit on error - this is now enforced
    set -e
    
    # # Handle undefined variables
    # set -u
    
    # Set errexit option
    set -o errexit
    
    # Set pipefail option - ensures pipelines fail if any command fails
    set -o pipefail
    
    # Start the tracing system
    start_tracing
}
