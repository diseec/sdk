#!/bin/bash
# Test runner core functionality

# Source required facades
export TESTER_LIB_DIR="$KIT_SRC_DIR/lib/tester"
source "$TESTER_LIB_DIR/colors.sh"
source "$TESTER_LIB_DIR/assertions.sh"
source "$TESTER_LIB_DIR/utils.sh"

# Configuration
DEFAULT_TEST_PATTERN="*.test.sh"
TEST_TIMEOUT_SECONDS=${TEST_TIMEOUT_SECONDS:-300}

# Global state
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# Function to find all test files
find_test_files() {
    local search_pattern="${1:-$DEFAULT_TEST_PATTERN}"
    local search_dir="${2:-$KIT_DIR}"
    
    if [ ! -d "$search_dir" ]; then
        echo "Error: Directory '$search_dir' does not exist" >&2
        return 1
    fi
    
    find "$search_dir" -name "$search_pattern" -type f 2>/dev/null | sort
}

# Function to list all test files
list_test_files() {
    local test_files
    test_files=$(find_test_files)
    
    if [ -z "$test_files" ]; then
        echo -e "${COLOR_WARNING}No test files found in $KIT_DIR${NC}"
        echo -e "${COLOR_INFO}Searched for: $DEFAULT_TEST_PATTERN${NC}"
        return 0
    fi
    
    echo -e "${COLOR_INFO}Available test files:${NC}"
    local count=0
    while read -r file; do
        if [ -n "$file" ]; then
            count=$((count + 1))
            # Show relative path from KIT_DIR
            local rel_path="${file#$KIT_DIR/}"
            echo -e "  ${COLOR_HIGHLIGHT}$count.${NC} $rel_path"
        fi
    done <<< "$test_files"
    
    echo -e "\n${COLOR_INFO}Total: $count test file(s)${NC}"
}

# Function to validate test file
validate_test_file() {
    local test_file="$1"
    
    if [ ! -f "$test_file" ]; then
        echo -e "${COLOR_ERROR}Error: Test file '$test_file' not found${NC}" >&2
        return 1
    fi
    
    if [ ! -r "$test_file" ]; then
        echo -e "${COLOR_ERROR}Error: Test file '$test_file' is not readable${NC}" >&2
        return 1
    fi
    
    return 0
}

# Function to setup test environment for a single test
setup_single_test_env() {
    local test_file="$1"
    
    # Initialize test state
    init_test_state "$test_file"
    
    # Set up environment variables
    export CURRENT_TEST_FILE="$test_file"
    export TEST_FILE_DIR="$(dirname "$test_file")"
    export TEST_FILE_NAME="$(basename "$test_file")"
    
    # Setup temporary environment
    setup_test_env
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
            echo -e "${COLOR_WARNING}Warning: Making '$test_file' executable${NC}"
        fi
        chmod +x "$test_file" || {
            echo -e "${COLOR_ERROR}Error: Failed to make test file executable${NC}" >&2
            return 1
        }
    fi
    
    local rel_path="${test_file#$KIT_DIR/}"
    
    if [ "$quiet" != "true" ]; then
        echo -e "${COLOR_INFO}Running test: $rel_path${NC}"
    fi
    
    # Setup test environment
    setup_single_test_env "$test_file"
    
    # Create test execution script
    local test_runner_script=$(create_temp_file)
    cat > "$test_runner_script" << 'EOF'
#!/bin/bash
set -euo pipefail

# Source all test framework facades
source "$TESTER_LIB_DIR/colors.sh"
source "$TESTER_LIB_DIR/assertions.sh" 
source "$TESTER_LIB_DIR/utils.sh"

# Run the test file
source "$1"

# Return the test results
exit_code=0
if [ $FAILED_COUNT -gt 0 ]; then
    exit_code=1
fi

echo "TEST_STATS:$TEST_COUNT:$ASSERTION_COUNT:$PASSED_COUNT:$FAILED_COUNT"
exit $exit_code
EOF
    
    chmod +x "$test_runner_script"
    
    # Execute the test with timeout
    local exit_code=0
    local output=""
    local test_stats=""
    
    if [ "$verbose" = "true" ]; then
        # Show all output in verbose mode
        if timeout "$TEST_TIMEOUT_SECONDS" bash "$test_runner_script" "$test_file"; then
            exit_code=0
        else
            local timeout_exit=$?
            if [ $timeout_exit -eq 124 ]; then
                echo -e "${COLOR_ERROR}Test timed out after ${TEST_TIMEOUT_SECONDS} seconds${NC}"
                exit_code=1
            else
                exit_code=1
            fi
        fi
    else
        # Capture output
        if output=$(timeout "$TEST_TIMEOUT_SECONDS" bash "$test_runner_script" "$test_file" 2>&1); then
            exit_code=0
        else
            local timeout_exit=$?
            if [ $timeout_exit -eq 124 ]; then
                echo -e "${COLOR_ERROR}Test timed out after ${TEST_TIMEOUT_SECONDS} seconds${NC}"
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
            # Parse stats: TEST_STATS:tests:assertions:passed:failed
            local stats_array=(${test_stats#TEST_STATS:})
            if [ ${#stats_array[@]} -eq 4 ]; then
                TOTAL_TESTS=$((TOTAL_TESTS + ${stats_array[0]}))
                TOTAL_PASSED=$((TOTAL_PASSED + ${stats_array[2]}))
                TOTAL_FAILED=$((TOTAL_FAILED + ${stats_array[3]}))
            fi
        fi
    fi
    
    # Clean up
    cleanup_temp "$test_runner_script"
    
    # Report result
    if [ $exit_code -eq 0 ]; then
        if [ "$quiet" != "true" ]; then
            echo -e "${COLOR_SUCCESS}✔ PASSED: $rel_path${NC}"
        fi
        return 0
    else
        if [ "$quiet" != "true" ]; then
            echo -e "${COLOR_ERROR}✗ FAILED: $rel_path${NC}"
        fi
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    local verbose="${1:-false}"
    local quiet="${2:-false}"
    local test_files
    
    test_files=$(find_test_files)
    
    if [ -z "$test_files" ]; then
        echo -e "${COLOR_WARNING}No test files found in $KIT_DIR${NC}"
        echo -e "${COLOR_INFO}Searched for: $DEFAULT_TEST_PATTERN${NC}"
        return 0
    fi
    
    local total=0
    local passed=0
    local failed=0
    
    if [ "$quiet" != "true" ]; then
        echo -e "${COLOR_INFO}Running all tests...${NC}\n"
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
    fi
    
    if [ $failed -eq 0 ]; then
        echo -e "\n${COLOR_SUCCESS}${BOLD}All tests passed!${NC}"
    else
        echo -e "\n${COLOR_ERROR}${BOLD}Some tests failed!${NC}"
    fi
}
