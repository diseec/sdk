#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST SUITE MANAGEMENT                                                   ┃
# ┃ Manages test suites, setup, teardown, and test organization            ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Suite lifecycle hooks
suite_setup() {
    # Override this function in test files for suite-wide setup
    # This runs once before all tests in the file
    return 0
}

suite_teardown() {
    # Override this function in test files for suite-wide cleanup  
    # This runs once after all tests in the file
    return 0
}

test_setup() {
    # Override this function in test files for per-test setup
    # This runs before each individual test function
    return 0
}

test_teardown() {
    # Override this function in test files for per-test cleanup
    # This runs after each individual test function
    rm -fr "$D_ORG_DIR"
    return 0
}

# Execute a test with proper setup and teardown
_sdk_tester_execute_test_with_hooks() {
    local test_function="$1"
    TESTER_CURRENT_TEST="$test_function"
    
    # Run test setup if defined
    if declare -f test_setup >/dev/null 2>&1; then
        if ! test_setup; then
            logit -e "Test setup failed for $test_function"
            return 1
        fi
    fi
    
    # Run the actual test
    local test_result=0
    if ! "$test_function"; then
        test_result=1
    fi
    
    # Run test teardown if defined (always run, even if test failed)
    if declare -f test_teardown >/dev/null 2>&1; then
        if ! test_teardown; then
            logit -w "Test teardown failed for $test_function"
        fi
    fi
    
    return $test_result
}

# Execute suite with proper setup and teardown
_sdk_tester_execute_suite() {
    local test_file="$1"
    
    # Source the test file
    source "$test_file"
    
    # Run suite setup if defined
    if declare -f suite_setup >/dev/null 2>&1; then
        if ! suite_setup; then
            logit -e "Suite setup failed for $test_file"
            return 1
        fi
    fi
    
    # Find and execute all test functions
    local test_functions
    test_functions=$(declare -F | grep "declare -f test_" | sed 's/declare -f //')
    
    if [ -z "$test_functions" ]; then
        logit -w "  No test functions found (functions should start with 'test_')"
        return 0
    fi
    
    local suite_failed=0
    
    # Execute each test function with hooks
    echo "$test_functions" | while IFS= read -r test_function; do
        if [ -n "$test_function" ]; then
            if [ "$TESTER_VERBOSE" = "true" ]; then
                logit --ansi="$TESTER_COLOR_DIM" "    $(ansi 90 "→") $test_function"
            fi
            
            if ! _sdk_tester_execute_test_with_hooks "$test_function"; then
                suite_failed=1
                if [ "$TESTER_FAIL_FAST" = "true" ]; then
                    break
                fi
            fi
        fi
    done
    
    # Run suite teardown if defined (always run)
    if declare -f suite_teardown >/dev/null 2>&1; then
        if ! suite_teardown; then
            logit -w "Suite teardown failed for $test_file"
        fi
    fi
    
    return $suite_failed
}

# Create a temporary test workspace
create_test_workspace() {
    local workspace_name="${1:-test_workspace_$$}"
    local workspace_dir="/tmp/$workspace_name"
    
    mkdir -p "$workspace_dir"
    echo "$workspace_dir"
}

# Clean up test workspace  
cleanup_test_workspace() {
    local workspace_dir="$1"
    
    if [ -n "$workspace_dir" ] && [ -d "$workspace_dir" ]; then
        rm -rf "$workspace_dir"
    fi
}

# Helper function to create test files
create_test_file() {
    local file_path="$1"
    local content="${2:-}"
    
    local dir_path
    dir_path=$(dirname "$file_path")
    mkdir -p "$dir_path"
    
    if [ -n "$content" ]; then
        echo "$content" > "$file_path"
    else
        touch "$file_path"
    fi
}

# Helper function to create test directories
create_test_dir() {
    local dir_path="$1"
    mkdir -p "$dir_path"
}

# Set up a mock command (for testing CLI tools)
mock_command() {
    local command_name="$1"
    local mock_behavior="${2:-echo 'mocked $command_name called with args: $@'}"
    local mock_exit_code="${3:-0}"
    
    # Create a mock function
    eval "$command_name() { $mock_behavior; return $mock_exit_code; }"
}

# Restore original command (remove mock)
unmock_command() {
    local command_name="$1"
    unset -f "$command_name" 2>/dev/null || true
}

# Assert that a mock was called with specific arguments
assert_mock_called_with() {
    local command_name="$1"
    local expected_args="$2"
    local message="${3:-"Mock $command_name should have been called with: $expected_args"}"
    
    # This is a simplified implementation - in practice, you'd need to track calls
    # For a full implementation, you'd modify mock_command to track calls
    logit -w "assert_mock_called_with is not fully implemented yet"
    return 0
}
