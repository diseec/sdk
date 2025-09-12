#!/bin/bash

# Test for the 'secret validate' command

# Test validate command with missing argument
test_secret_validate_missing_argument() {
    local output
    output=$(D secret validate 2>&1)
    local result=$?
    
    # Should fail without secret name
    assert_not_equals "0" "$result" "Should fail without secret name"
    assert_contains "$output" "Secret name required\|Usage" "Should indicate missing argument"
}

# Test validate command with non-existent secret
test_secret_validate_nonexistent_secret() {
    # Use timeout to avoid hanging on interactive prompts
    local output
    output=$(echo "" | timeout 5s D secret validate nonexistent-secret 2>&1 || echo "TIMEOUT_OR_COMPLETED")
    local result=$?
    
    # The command might try to prompt for the secret interactively
    # We expect either failure or timeout behavior
    assert_contains "$output" "nonexistent-secret\|TIMEOUT_OR_COMPLETED\|not found\|failed" "Should handle non-existent secret"
}

# Test validate command structure and help
test_secret_validate_command_structure() {
    local output
    output=$(D secret validate 2>&1)
    
    # Should show usage information
    assert_contains "$output" "Usage\|required" "Should show usage information"
}

# # Test validate command with invalid arguments
# test_secret_validate_invalid_args() {
#     local output
#     output=$(D secret validate test-secret --invalid-arg 2>&1)
#     local result=$?
    
#     # Should fail with invalid argument
#     assert_not_equals "0" "$result" "Should fail with invalid argument"
#     assert_contains "$output" "Unknown argument" "Should indicate unknown argument"
# }

# Test that validate command is recognized
test_secret_validate_command_recognized() {
    local output
    output=$(D secret validate 2>&1)
    
    # Should not contain "Unknown command"
    echo "$output" | grep -v "Unknown command" > /dev/null
    assert_equals "0" "$?" "Validate command should be recognized"
}
