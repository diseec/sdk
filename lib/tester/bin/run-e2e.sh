#!/bin/bash
# E2E test runner
# This script is responsible for discovering and running E2E tests

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source bootstrap modules
source "$TESTING_DIR/bootstrap/bootstrap.sh"
source "$TESTING_DIR/bootstrap/runner.sh"
source "$TESTING_DIR/bootstrap/discovery.sh"
source "$TESTING_DIR/frameworks/e2e/framework.sh"

# Default configuration for E2E tests
DEFAULT_TEST_PATTERN="*.e2e.test.sh"
DEFAULT_TEST_DIR="$D_SDK_DIR/tests/e2e"
TEST_TIMEOUT_SECONDS=${TEST_TIMEOUT_SECONDS:-180}

# Function to show help
show_help() {
    cat << EOF
SDK E2E Test Runner

Usage:
    $(basename "$0") [OPTIONS] [TEST_FILE]

Options:
    --help, -h      Show this help message
    --list, -l      List available E2E tests
    --verbose, -v   Enable verbose output
    --quiet, -q     Minimal output (only results)
    --timeout N     Set test timeout in seconds (default: $TEST_TIMEOUT_SECONDS)
    --pattern P     Use custom file pattern (default: "$DEFAULT_TEST_PATTERN")
    --dir D         Specify test directory (default: $DEFAULT_TEST_DIR)

Arguments:
    TEST_FILE       Path to specific test file to run (optional)

Examples:
    $(basename "$0")                     # Run all E2E tests
    $(basename "$0") --list              # List available E2E tests
    $(basename "$0") path/to/test.sh     # Run specific test file
    $(basename "$0") --verbose           # Run with verbose output

EOF
}

# Main function
main() {
    local list_only=false
    local verbose=false
    local quiet=false
    local specific_test=""
    local test_pattern="$DEFAULT_TEST_PATTERN"
    local test_dir="$DEFAULT_TEST_DIR"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --list|-l)
                list_only=true
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --quiet|-q)
                quiet=true
                shift
                ;;
            --timeout)
                if [ -z "${2:-}" ]; then
                    log_error "--timeout requires a value"
                    exit 1
                fi
                export TEST_TIMEOUT_SECONDS="$2"
                shift 2
                ;;
            --pattern)
                if [ -z "${2:-}" ]; then
                    log_error "--pattern requires a value"
                    exit 1
                fi
                test_pattern="$2"
                shift 2
                ;;
            --dir)
                if [ -z "${2:-}" ]; then
                    log_error "--dir requires a value"
                    exit 1
                fi
                test_dir="$2"
                shift 2
                ;;
            --*)
                log_error "Unknown option '$1'"
                exit 1
                ;;
            *)
                specific_test="$1"
                shift
                ;;
        esac
    done
    
    # Handle list option
    if [ "$list_only" = "true" ]; then
        list_test_files "$test_dir" "$test_pattern"
        exit 0
    fi
    
    # Handle specific test file
    if [ -n "$specific_test" ]; then
        # Convert relative path to absolute if needed
        if [[ "$specific_test" != /* ]]; then
            specific_test="$D_SDK_DIR/$specific_test"
        fi
        
        if run_test_file "$specific_test" "$verbose" "$quiet"; then
            exit 0
        else
            exit 1
        fi
    fi
    
    # Run all tests
    if run_all_tests "$test_dir" "$test_pattern" "$verbose" "$quiet"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
