#!/bin/bash

# TEST: Basic Assertion Example
# DESCRIPTION: Demonstrates basic assertion capabilities of the testing framework

# Source testing framework (this is handled automatically when the test is run by the framework)
source_once "$D_SDK_DIR/lib/tester/index.sh"

# Mark the beginning of a test section
sdk_lib_tester_utils_section "Basic Assertions"

# Test equality assertions
assert_equal "hello" "hello" "String equality check should pass"
assert_not_equal "hello" "world" "String inequality check should pass"

# Test boolean assertions
assert_true "[[ 2 -eq 2 ]]" "Numeric equality should be true"
assert_false "[[ 2 -eq 3 ]]" "Numeric inequality should be false"

# Test string operations
assert_contains "hello world" "world" "String should contain substring"
assert_not_contains "hello world" "universe" "String should not contain substring"

# Mark a new test section
sdk_lib_tester_utils_section "Command Execution"

# Test command execution
assert_success "echo 'command output'" "Echo command should succeed"
assert_failure "exit 1" 1 "Exit with code 1 should fail with expected exit code"

# Test file operations
touch "$SDK_TEST_TMP_DIR/test-file.txt"
echo "test content" > "$SDK_TEST_TMP_DIR/test-file.txt"

assert_file_exists "$SDK_TEST_TMP_DIR/test-file.txt" "File should exist"
assert_file_contains "$SDK_TEST_TMP_DIR/test-file.txt" "test content" "File should contain content"

# Print assertion stats (this is handled automatically when the test is run by the framework)
sdk_lib_tester_assert_stats

# Exit with the number of failed assertions (0 means all passed)
exit $(( SDK_TESTER_ASSERT_FAILED > 0 ? 1 : 0 ))
