#!/bin/bash
# Bootstrap module for the testing framework
# This script sets up the testing environment and sources required dependencies

# Ensure the script fails on errors
set -euo pipefail

# Determine script directory
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTING_DIR="$(cd "$BOOTSTRAP_DIR/.." && pwd)"

# Ensure D_SDK_DIR is set
if [ -z "${D_SDK_DIR:-}" ]; then
    # Try to autodetect D_SDK_DIR
    if [ -d "$TESTING_DIR/../../.." ]; then
        export D_SDK_DIR="$(cd "$TESTING_DIR/../../.." && pwd)"
    else
        echo "Error: D_SDK_DIR environment variable is not set and could not be autodetected" >&2
        exit 1
    fi
fi

# Set default environment variables
export TEST_TIMEOUT_SECONDS=${TEST_TIMEOUT_SECONDS:-60}
export TESTING_LIB_DIR="$TESTING_DIR/lib"

# Source required libraries
source "$TESTING_LIB_DIR/formatting.sh"
source "$TESTING_LIB_DIR/assertions.sh"
source "$TESTING_LIB_DIR/utils.sh"
source "$TESTING_LIB_DIR/mocks.sh"

# Create a temp directory for test artifacts if it doesn't exist
if [ -z "${TEST_TEMP_DIR:-}" ]; then
    export TEST_TEMP_DIR=$(mktemp -d)
    # Add cleanup trap
    trap 'rm -rf "$TEST_TEMP_DIR"' EXIT
fi

# Set up global test counters
export TOTAL_TESTS=0
export TOTAL_PASSED=0
export TOTAL_FAILED=0
export TOTAL_SKIPPED=0

# Set up per-file test counters
export TEST_COUNT=0
export PASSED_COUNT=0
export FAILED_COUNT=0
export ASSERTION_COUNT=0
export SKIPPED_COUNT=0

# Utility function to log a message
log_message() {
    local level="$1"
    local message="$2"
    local color="$COLOR_INFO"
    
    case "$level" in
        INFO)    color="$COLOR_INFO" ;;
        WARNING) color="$COLOR_WARNING" ;;
        ERROR)   color="$COLOR_ERROR" ;;
        SUCCESS) color="$COLOR_SUCCESS" ;;
        *)       color="$COLOR_INFO" ;;
    esac
    
    echo -e "${color}[$level]${NC} $message"
}

# Logging functions
log_info() {
    log_message "INFO" "$1"
}

log_warning() {
    log_message "WARNING" "$1"
}

log_error() {
    log_message "ERROR" "$1" >&2
}

log_success() {
    log_message "SUCCESS" "$1"
}

log_section() {
    echo -e "\n${BOLD}${COLOR_HIGHLIGHT}=== $1 ===${NC}"
}

# Export functions
export -f log_message log_info log_warning log_error log_success log_section
