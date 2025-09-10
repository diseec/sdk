#!/bin/bash

# Test for the 'secret exists' command

# Test exists command with missing argument
test_secret_exists_missing_argument() {
    local output
    output=$(D secret exists 2>&1)
    local result=$?
    
    # Verify command fails without secret name
    assert_not_equals "0" "$result" "Should fail without secret name"
    assert_contains "$output" "Secret name required\|Usage" "Should indicate missing argument"
    
    # Verify help or usage information is displayed
    assert_contains "$output" "exists" "Should mention the command name in usage info"
    assert_contains "$output" "D secret exists" "Should show command syntax"
}

# Test exists command with non-existent secret
test_secret_exists_nonexistent_secret() {
    # Ensure the secret doesn't exist
    local nonexistent="NONEXISTENT_SECRET"
    rm -f "$SECRETS_DIR/$nonexistent" 2>/dev/null
    
    # Check if the secret exists
    local output
    output=$(D secret exists $nonexistent 2>&1)
    local result=$?
    
    # Verify command returns false for non-existent secret
    assert_not_equals "0" "$result" "Should return false (non-zero) for non-existent secret"
    assert_contains "$output" "does not exist" "Should indicate the secret does not exist"
    assert_contains "$output" "$nonexistent" "Should mention the specific secret name"
}

# Test exists command with quiet flag for non-existent secret
test_secret_exists_quiet_nonexistent() {
    # Ensure the secret doesn't exist
    local nonexistent="QUIET_NONEXISTENT_SECRET"
    rm -f "$SECRETS_DIR/$nonexistent" 2>/dev/null
    
    # Check with quiet flag
    local output
    output=$(D secret exists $nonexistent --quiet 2>&1)
    local result=$?
    
    # Verify quiet mode behavior for non-existent secret
    assert_not_equals "0" "$result" "Should return false for non-existent secret even in quiet mode"
    assert_equals "" "$output" "With quiet flag, output should be empty"
    
    # Compare with normal (non-quiet) output
    local normal_output
    normal_output=$(D secret exists $nonexistent 2>&1)
    assert_not_equals "" "$normal_output" "Normal mode should produce output unlike quiet mode"
}

# Test exists command with invalid arguments
test_secret_exists_invalid_args() {
    local output
    output=$(D secret exists TEST_SECRET --invalid-arg 2>&1)
    local result=$?
    
    # Verify command fails with invalid argument
    assert_not_equals "0" "$result" "Should fail with invalid argument"
    assert_contains "$output" "Unknown argument" "Should indicate unknown argument"
    assert_contains "$output" "invalid-arg" "Should mention the specific invalid argument"
    
    # Test with multiple invalid arguments
    local output2
    output2=$(D secret exists TEST_SECRET --bad1 --bad2 2>&1)
    local result2=$?
    
    # Verify command fails with multiple invalid arguments
    assert_not_equals "0" "$result2" "Should fail with multiple invalid arguments"
    assert_contains "$output2" "Unknown argument" "Should indicate unknown argument"
}

# Test command structure - should be recognized
test_secret_exists_command_recognized() {
    local output
    output=$(D secret exists 2>&1)
    local result=$?
    
    # Command should be recognized even if it fails due to missing argument
    assert_not_contains "$output" "Unknown command" "Command should be recognized"
    assert_not_contains "$output" "not found" "Command should be recognized"
    
    # Verify command is in help output
    local help_output
    help_output=$(D secret help 2>&1)
    assert_contains "$help_output" "exists" "Command should be listed in help output"
}

# Test exists command with existing secret
test_secret_exists_with_existing_secret() {
    # Ensure test secret exists
    echo "test_value" > "$SECRETS_DIR/EXISTING_SECRET"
    
    # Check if secret exists
    local output
    output=$(D secret exists EXISTING_SECRET 2>&1)
    local result=$?
    
    # Verify command returns true for existing secret
    assert_equals "0" "$result" "Should return true (zero) for existing secret"
    assert_contains "$output" "exists\|found" "Should indicate the secret exists"
    assert_contains "$output" "EXISTING_SECRET" "Should mention the specific secret name"
}

# Test exists command with quiet flag for existing secret
test_secret_exists_quiet_existing() {
    # Ensure test secret exists
    echo "quiet_test_value" > "$SECRETS_DIR/QUIET_EXISTING_SECRET"
    
    # Check with quiet flag
    local output
    output=$(D secret exists QUIET_EXISTING_SECRET --quiet 2>&1)
    local result=$?
    
    # Verify quiet mode behavior for existing secret
    assert_equals "0" "$result" "Should return true for existing secret in quiet mode"
    assert_equals "" "$output" "With quiet flag, output should be empty"
}
