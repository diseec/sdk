#!/bin/bash
# Main test runner for the SDK testing framework
# This script provides a unified interface for running unit and E2E tests

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source core modules
source "$TESTING_DIR/core/bootstrap.sh"

# Function to show help
show_help() {
    cat << EOF
SDK Test Runner

Usage:
    $(basename "$0") [OPTIONS] [TEST_FILE]

Options:
    --help, -h      Show this help message
    --unit, -u      Run only unit tests (default if no option specified)
    --e2e, -e       Run only E2E tests
    --all, -a       Run both unit and E2E tests
    --list, -l      List available tests
    --verbose, -v   Enable verbose output
    --quiet, -q     Minimal output (only results)
    --timeout N     Set test timeout in seconds (default: 60)
    --pattern P     Use custom file pattern (default: "*.test.sh" for unit, "*.e2e.test.sh" for E2E)

Arguments:
    TEST_FILE       Path to specific test file to run (optional)

Examples:
    $(basename "$0")                     # Run unit tests
    $(basename "$0") --e2e               # Run E2E tests
    $(basename "$0") --all               # Run all tests
    $(basename "$0") path/to/test.sh     # Run specific test
    $(basename "$0") --list --e2e        # List E2E tests

EOF
}

# Main function
main() {
    local run_unit=true
    local run_e2e=false
    local list_only=false
    local verbose=false
    local quiet=false
    local timeout=""
    local pattern=""
    local specific_test=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --unit|-u)
                run_unit=true
                run_e2e=false
                shift
                ;;
            --e2e|-e)
                run_unit=false
                run_e2e=true
                shift
                ;;
            --all|-a)
                run_unit=true
                run_e2e=true
                shift
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
                timeout="$2"
                shift 2
                ;;
            --pattern)
                if [ -z "${2:-}" ]; then
                    log_error "--pattern requires a value"
                    exit 1
                fi
                pattern="$2"
                shift 2
                ;;
            --*)
                log_error "Unknown option '$1'"
                exit 1
                ;;
            *)
                if [ -n "$specific_test" ]; then
                    log_error "Multiple test files specified"
                    exit 1
                fi
                specific_test="$1"
                
                # Automatically determine test type from file path
                if [[ "$specific_test" == *".e2e.test.sh" ]]; then
                    run_unit=false
                    run_e2e=true
                elif [[ "$specific_test" == *.test.sh ]]; then
                    run_unit=true
                    run_e2e=false
                fi
                
                shift
                ;;
        esac
    done
    
    # Build arguments for test runners
    local unit_args=""
    local e2e_args=""
    
    if [ "$list_only" = "true" ]; then
        unit_args="$unit_args --list"
        e2e_args="$e2e_args --list"
    fi
    
    if [ "$verbose" = "true" ]; then
        unit_args="$unit_args --verbose"
        e2e_args="$e2e_args --verbose"
    fi
    
    if [ "$quiet" = "true" ]; then
        unit_args="$unit_args --quiet"
        e2e_args="$e2e_args --quiet"
    fi
    
    if [ -n "$timeout" ]; then
        unit_args="$unit_args --timeout $timeout"
        e2e_args="$e2e_args --timeout $timeout"
    fi
    
    if [ -n "$pattern" ]; then
        unit_args="$unit_args --pattern $pattern"
        e2e_args="$e2e_args --pattern $pattern"
    fi
    
    if [ -n "$specific_test" ]; then
        unit_args="$unit_args $specific_test"
        e2e_args="$e2e_args $specific_test"
    fi
    
    # Run tests
    local unit_result=0
    local e2e_result=0
    
    if [ "$run_unit" = "true" ]; then
        if [ "$quiet" != "true" ]; then
            log_section "Running Unit Tests"
        fi
        "$SCRIPT_DIR/run-unit.sh" $unit_args
        unit_result=$?
    fi
    
    if [ "$run_e2e" = "true" ]; then
        if [ "$quiet" != "true" ]; then
            log_section "Running E2E Tests"
        fi
        "$SCRIPT_DIR/run-e2e.sh" $e2e_args
        e2e_result=$?
    fi
    
    # Determine exit code
    if [ $unit_result -ne 0 ] || [ $e2e_result -ne 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
