#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ EXAMPLE TEST FILE                                                       ┃
# ┃ This demonstrates how to write tests using the DISEEC SDK tester       ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Optional: Suite setup - runs once before all tests in this file
setup_test() {
    # Create some test files
    create_test_file "$TEST_WORKSPACE/sample.txt" "Hello, World!"
    create_test_file "$TEST_WORKSPACE/empty.txt"
    create_test_dir "$TEST_WORKSPACE/subdir"
}

# Optional: Test setup - runs before each individual test
setup_test() {
    # Set up any per-test state
    export TEST_VAR="initialized"
}

# Optional: Test teardown - runs after each individual test  
teardown_test() {
    # Clean up any per-test state
    unset TEST_VAR
}

# Test functions must start with "test_"

test_basic_assertions() {
    # Test equality assertions
    assert_equals "hello" "hello" "Strings should be equal"
    assert_not_equals "hello" "world" "Different strings should not be equal"
    
    # Test numeric comparisons
    assert_greater_than 10 5 "10 should be greater than 5"
    assert_less_than 3 7 "3 should be less than 7"
}

test_string_operations() {
    local test_string="The quick brown fox jumps over the lazy dog"
    
    # Test string contains
    assert_contains "$test_string" "quick" "Should contain 'quick'"
    assert_contains "$test_string" "fox" "Should contain 'fox'"
    assert_not_contains "$test_string" "cat" "Should not contain 'cat'"
    
    # Test regex matching
    assert_matches "$test_string" "^The.*dog$" "Should match start and end pattern"
    assert_matches "test@example.com" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "Should match email pattern"
}

test_file_operations() {
    # Test file existence
    assert_file_exists "$TEST_WORKSPACE/sample.txt" "Sample file should exist"
    assert_file_not_exists "$TEST_WORKSPACE/nonexistent.txt" "Nonexistent file should not exist"
    
    # Test directory existence
    assert_dir_exists "$TEST_WORKSPACE" "Test workspace should exist"
    assert_dir_exists "$TEST_WORKSPACE/subdir" "Subdirectory should exist"
}

test_command_execution() {
    # Test command success and failure
    assert_command_success "echo 'hello world'" "Echo command should succeed"
    assert_command_success "ls $TEST_WORKSPACE" "Listing test workspace should succeed"
    
    assert_command_fails "ls /nonexistent/directory/that/does/not/exist" "Listing nonexistent directory should fail"
    assert_command_fails "false" "False command should fail"
}

test_empty_and_not_empty() {
    local empty_var=""
    local non_empty_var="content"
    
    assert_empty "$empty_var" "Empty variable should be empty"
    assert_not_empty "$non_empty_var" "Non-empty variable should not be empty"
    assert_not_empty "$TEST_VAR" "TEST_VAR from setup should not be empty"
}

test_conditional_tests() {
    # Sometimes you might want to skip tests based on conditions
    if [ ! -x "$(command -v git)" ]; then
        skip_test "Git not available, skipping git-related test"
        return 0
    fi
    
    # This test will only run if git is available
    assert_command_success "git --version" "Git should be available and working"
}

test_failure_demonstration() {
    # This test will intentionally fail to show error reporting
    # Uncomment the line below to see failure output:
    # assert_equals "expected" "actual" "This assertion will fail"
    
    # This test passes
    assert_equals "same" "same" "This assertion will pass"
}

# You can also test your own functions
my_helper_function() {
    local input="$1"
    echo "processed: $input"
}

test_custom_functions() {
    local result
    result=$(my_helper_function "test input")
    
    assert_equals "processed: test input" "$result" "Helper function should process input correctly"
    assert_contains "$result" "processed:" "Result should contain prefix"
}
