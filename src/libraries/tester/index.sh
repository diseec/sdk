#!/bin/bash

# Test runner script for the kit project
# Usage: 
#   ./index.sh                    - Run all tests
#   ./index.sh --list             - List all test files
#   ./index.sh path/to/test.sh    - Run specific test file
#   ./index.sh --help             - Show help

set -euo pipefail

# Get script directory and source the test runner
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/runner.sh"

# Ensure KIT_DIR is set
if [ -z "${KIT_DIR:-}" ]; then
    echo -e "${COLOR_ERROR}Error: KIT_DIR environment variable is not set${NC}" >&2
    exit 1
fi

# Function to show help
show_help() {
    cat << EOF
Test Runner for Kit Project

Usage:
    $0 [OPTIONS] [TEST_FILE]

Options:
    --help, -h      Show this help message
    --list, -l      List all available test files
    --verbose, -v   Enable verbose output (show all test output)
    --quiet, -q     Minimal output (only results)
    --timeout N     Set test timeout in seconds (default: $TEST_TIMEOUT_SECONDS)

Arguments:
    TEST_FILE       Relative path to specific test file to run (optional)

Examples:
    $0                           # Run all tests
    $0 --list                    # List all test files
    $0 facades/ai/tests/index.test.sh  # Run specific test file
    $0 --verbose                 # Run all tests with verbose output
    $0 --timeout 60              # Run tests with 60 second timeout

Test Helper Functions Available in Tests:
    test_section "Section Name"     # Print section header
    test_case "Test Case Name"      # Print test case header
    
    Assertions:
    assert_success "desc" command   # Assert command succeeds
    assert_failure "desc" command   # Assert command fails
    assert_equals "desc" exp act    # Assert strings equal
    assert_not_equals "desc" exp act # Assert strings not equal
    assert_contains "desc" str sub  # Assert string contains substring
    assert_not_contains "desc" str sub # Assert string doesn't contain substring
    assert_matches "desc" str regex # Assert string matches regex
    assert_function_exists "desc" fn # Assert function exists
    assert_variable_set "desc" var  # Assert variable is set
    assert_file_exists "desc" path  # Assert file exists
    assert_directory_exists "desc" path # Assert directory exists
    
    Utilities:
    test_info "message"             # Print info message
    test_warn "message"             # Print warning message
    test_error "message"            # Print error message
    test_skip "reason"              # Skip test with reason
    source_module "path" ["desc"]   # Source module with error handling
    create_temp_file ["content"]    # Create temporary file
    create_temp_dir                 # Create temporary directory
    cleanup_temp "path"             # Clean up temporary files/dirs
    time_command "desc" command     # Measure command execution time
    mock_command "name" "behavior"  # Mock a command for testing
    restore_command "name"          # Restore original command

Environment Variables:
    TEST_TIMEOUT_SECONDS           # Test timeout (default: 300)
    NO_COLOR                       # Disable colored output
    TEST_TEMP_DIR                  # Temporary directory for test artifacts
    CURRENT_TEST_FILE              # Currently running test file

EOF
}

# Main script logic
main() {
    local verbose=false
    local quiet=false
    local list_only=false
    local specific_test=""
    
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
                    echo -e "${COLOR_ERROR}Error: --timeout requires a value${NC}" >&2
                    exit 1
                fi
                export TEST_TIMEOUT_SECONDS="$2"
                shift 2
                ;;
            --*)
                echo -e "${COLOR_ERROR}Error: Unknown option '$1'${NC}" >&2
                echo "Use --help for usage information."
                exit 1
                ;;
            *)
                if [ -n "$specific_test" ]; then
                    echo -e "${COLOR_ERROR}Error: Multiple test files specified${NC}" >&2
                    exit 1
                fi
                specific_test="$1"
                shift
                ;;
        esac
    done
    
    # Handle list option
    if [ "$list_only" = "true" ]; then
        list_test_files
        exit 0
    fi
    
    # Handle specific test file
    if [ -n "$specific_test" ]; then
        # Convert relative path to absolute if needed
        if [[ "$specific_test" != /* ]]; then
            specific_test="$KIT_DIR/$specific_test"
        fi
        
        if run_test_file "$specific_test" "$verbose" "$quiet"; then
            exit 0
        else
            exit 1
        fi
    fi
    
    # Run all tests
    if run_all_tests "$verbose" "$quiet"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
