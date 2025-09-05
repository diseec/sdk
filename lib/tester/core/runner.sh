#!/bin/bash
# Test runner core functionality
# This script provides functions for running tests

# Function to validate a test file
validate_test_file() {
    local test_file="$1"
    
    if [ ! -f "$test_file" ]; then
        log_error "Test file '$test_file' not found"
        return 1
    fi
    
    if [ ! -r "$test_file" ]; then
        log_error "Test file '$test_file' is not readable"
        return 1
    fi
    
    return 0
}

# Function to setup test environment for a single test
setup_single_test_env() {
    local test_file="$1"
    
    # Initialize test state
    export TEST_COUNT=0
    export PASSED_COUNT=0
    export FAILED_COUNT=0
    export ASSERTION_COUNT=0
    export SKIPPED_COUNT=0
    export CURRENT_TEST_CASE=""
    export CURRENT_TEST_FILE="$test_file"
    export TEST_FILE_DIR="$(dirname "$test_file")"
    export TEST_FILE_NAME="$(basename "$test_file")"
    
    # Setup temporary environment
    export TEST_ORIGINAL_PWD=$(pwd)
    
    # Set up cleanup trap
    trap 'cleanup_test_env' EXIT
}

# Function to clean up test environment
cleanup_test_env() {
    # Return to original directory
    if [ -n "${TEST_ORIGINAL_PWD:-}" ]; then
        cd "$TEST_ORIGINAL_PWD" 2>/dev/null || true
    fi
}

# Function to run a single test file
run_test_file() {
    local test_file="$1"
    local verbose="${2:-false}"
    local quiet="${3:-false}"
    
    if ! validate_test_file "$test_file"; then
        return 1
    fi
    
    # Make executable if needed
    if [ ! -x "$test_file" ]; then
        if [ "$quiet" != "true" ]; then
            log_warning "Making '$test_file' executable"
        fi
        chmod +x "$test_file" || {
            log_error "Failed to make test file executable"
            return 1
        }
    fi
    
    local rel_path="${test_file#$D_SDK_DIR/}"
    
    if [ "$quiet" != "true" ]; then
        log_info "Running test: $rel_path"
    fi
    
    # Setup test environment
    setup_single_test_env "$test_file"
    
    # Create test execution script
    local test_runner_script=$(mktemp)
    cat > "$test_runner_script" << EOF
#!/bin/bash
set -euo pipefail

# Source all test framework facades
source "$TESTING_DIR/core/bootstrap.sh"

# Run the test file
source "$test_file"

# Return the test results
exit_code=0
if [ \$FAILED_COUNT -gt 0 ]; then
    exit_code=1
fi

echo "TEST_STATS:\$TEST_COUNT:\$ASSERTION_COUNT:\$PASSED_COUNT:\$FAILED_COUNT:\$SKIPPED_COUNT"
exit \$exit_code
EOF
    
    chmod +x "$test_runner_script"
    
    # Execute the test with timeout
    local exit_code=0
    local output=""
    local test_stats=""
    
    if [ "$verbose" = "true" ]; then
        # Show all output in verbose mode
        if timeout "$TEST_TIMEOUT_SECONDS" bash "$test_runner_script"; then
            exit_code=0
        else
            local timeout_exit=$?
            if [ $timeout_exit -eq 124 ]; then
                log_error "Test timed out after ${TEST_TIMEOUT_SECONDS} seconds"
                exit_code=1
            else
                exit_code=1
            fi
        fi
    else
        # Capture output
        if output=$(timeout "$TEST_TIMEOUT_SECONDS" bash "$test_runner_script" 2>&1); then
            exit_code=0
        else
            local timeout_exit=$?
            if [ $timeout_exit -eq 124 ]; then
                log_error "Test timed out after ${TEST_TIMEOUT_SECONDS} seconds"
                exit_code=1
            else
                exit_code=1
                if [ "$quiet" != "true" ]; then
                    # Show output only on failure
                    echo "$output" | grep -v "^TEST_STATS:" || true
                fi
            fi
        fi
    fi
    
    # Extract test statistics if available
    if [ -n "$output" ]; then
        test_stats=$(echo "$output" | grep "^TEST_STATS:" | tail -1 || true)
        if [ -n "$test_stats" ]; then
            # Parse stats: TEST_STATS:tests:assertions:passed:failed:skipped
            local stats_array=(${test_stats#TEST_STATS:})
            if [ ${#stats_array[@]} -eq 5 ]; then
                TOTAL_TESTS=$((TOTAL_TESTS + ${stats_array[0]}))
                TOTAL_PASSED=$((TOTAL_PASSED + ${stats_array[2]}))
                TOTAL_FAILED=$((TOTAL_FAILED + ${stats_array[3]}))
                TOTAL_SKIPPED=$((TOTAL_SKIPPED + ${stats_array[4]}))
            fi
        fi
    fi
    
    # Clean up
    rm -f "$test_runner_script"
    
    # Report result
    if [ $exit_code -eq 0 ]; then
        if [ "$quiet" != "true" ]; then
            log_success "✓ PASSED: $rel_path"
        fi
        return 0
    else
        if [ "$quiet" != "true" ]; then
            log_error "✗ FAILED: $rel_path"
        fi
        return 1
    fi
}

# Function to run all tests in a directory
run_all_tests() {
    local test_dir="$1"
    local test_pattern="$2"
    local verbose="${3:-false}"
    local quiet="${4:-false}"
    
    # Get all test files
    local test_files=$(find "$test_dir" -name "$test_pattern" -type f 2>/dev/null | sort)
    
    if [ -z "$test_files" ]; then
        log_warning "No test files found in $test_dir matching pattern $test_pattern"
        return 0
    fi
    
    local total=0
    local passed=0
    local failed=0
    
    if [ "$quiet" != "true" ]; then
        log_info "Running tests from $test_dir matching $test_pattern"
    fi
    
    while read -r test_file; do
        if [ -n "$test_file" ]; then
            total=$((total + 1))
            if run_test_file "$test_file" "$verbose" "$quiet"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi
            if [ "$quiet" != "true" ]; then
                echo # Add spacing between tests
            fi
        fi
    done <<< "$test_files"
    
    # Print summary
    print_test_summary $total $passed $failed
    
    # Return appropriate exit code
    if [ $failed -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Function to print test summary
print_test_summary() {
    local total="$1"
    local passed="$2"
    local failed="$3"
    
    echo -e "${BOLD}${COLOR_INFO}Test Summary:${NC}"
    echo -e "  Total Files:  $total"
    echo -e "  ${COLOR_SUCCESS}Passed: $passed${NC}"
    
    if [ $failed -gt 0 ]; then
        echo -e "  ${COLOR_ERROR}Failed: $failed${NC}"
    fi
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        echo -e "\n${BOLD}${COLOR_INFO}Detailed Stats:${NC}"
        echo -e "  Test Cases:   $TOTAL_TESTS"
        echo -e "  Assertions:   $((TOTAL_PASSED + TOTAL_FAILED))"
        echo -e "  ${COLOR_SUCCESS}Passed:       $TOTAL_PASSED${NC}"
        if [ $TOTAL_FAILED -gt 0 ]; then
            echo -e "  ${COLOR_ERROR}Failed:       $TOTAL_FAILED${NC}"
        fi
        if [ $TOTAL_SKIPPED -gt 0 ]; then
            echo -e "  ${COLOR_WARNING}Skipped:      $TOTAL_SKIPPED${NC}"
        fi
    fi
    
    if [ $failed -eq 0 ]; then
        echo -e "\n${COLOR_SUCCESS}${BOLD}All tests passed!${NC}"
    else
        echo -e "\n${COLOR_ERROR}${BOLD}Some tests failed!${NC}"
    fi
}
