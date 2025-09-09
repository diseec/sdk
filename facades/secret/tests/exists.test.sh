#!/bin/bash

# Test for the 'secret exists' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "secret_exists_tests")
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test exists command with missing argument
test_secret_exists_missing_argument() {
    local output
    output=$(cd "$TEST_WORKSPACE" && D secret exists 2>&1)
    local result=$?
    
    # Should fail without secret name
    assert_not_equals "0" "$result" "Should fail without secret name"
    assert_contains "$output" "Secret name required\|Usage" "Should indicate missing argument"
}

# Test exists command with non-existent secret
test_secret_exists_nonexistent_secret() {
    local output
    output=$(cd "$TEST_WORKSPACE" && D secret exists nonexistent-secret 2>&1)
    local result=$?
    
    # Should return non-zero (false) for non-existent secret
    assert_not_equals "0" "$result" "Should return false for non-existent secret"
    assert_contains "$output" "does not exist" "Should indicate secret does not exist"
}

# Test exists command with quiet flag
test_secret_exists_quiet_nonexistent() {
    local output
    output=$(cd "$TEST_WORKSPACE" && D secret exists nonexistent-secret --quiet 2>&1)
    local result=$?
    
    # Should return non-zero with minimal output
    assert_not_equals "0" "$result" "Should return false for non-existent secret"
    # With quiet flag, output should be minimal or empty
}

# Test exists command with invalid arguments
test_secret_exists_invalid_args() {
    local output
    output=$(cd "$TEST_WORKSPACE" && D secret exists test-secret --invalid-arg 2>&1)
    local result=$?
    
    # Should fail with invalid argument
    assert_not_equals "0" "$result" "Should fail with invalid argument"
    assert_contains "$output" "Unknown argument" "Should indicate unknown argument"
}

# Test command structure - should be recognized
test_secret_exists_command_recognized() {
    local output
    output=$(cd "$TEST_WORKSPACE" && D secret exists 2>&1)
    
    # Should not contain "Unknown command"
    echo "$output" | grep -v "Unknown command" > /dev/null
    assert_equals "0" "$?" "Command should be recognized"
}
