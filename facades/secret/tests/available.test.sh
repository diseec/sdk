#!/bin/bash

# Test for the 'secret available' command

# Test availability check basic functionality
test_secret_available_basic() {
    local output
    output=$(D secret available 2>&1)
    local result=$?
    
    # Command should succeed regardless of OpenSSL availability
    assert_equals "0" "$result" "Basic availability check should always return success"
    
    # Should contain availability information
    assert_contains "$output" "OpenSSL" "Should mention OpenSSL"
    
    # Verify the output contains definitive information about availability
    if command -v openssl >/dev/null 2>&1; then
        assert_contains "$output" "OpenSSL is available" "Should indicate OpenSSL is available"
    else
        assert_contains "$output" "OpenSSL is not available" "Should indicate OpenSSL is not available"
    fi
    
    # Should show secrets directory information
    assert_contains "$output" "Secrets Directory" "Should mention secrets directory"
    assert_contains "$output" "$SECRETS_DIR" "Should show the correct secrets directory path"
}

# Test availability check with quiet flag
test_secret_available_quiet() {
    # Determine if OpenSSL is actually available on the system
    local openssl_available=0
    if ! command -v openssl >/dev/null 2>&1; then
        openssl_available=1
    fi
    
    # Test with quiet flag
    local output
    output=$(D secret available --quiet 2>&1)
    local result=$?
    
    # Verify exit code based on actual OpenSSL availability
    if [ "$openssl_available" -eq 0 ]; then
        assert_equals "0" "$result" "Quiet mode should succeed when OpenSSL is available"
    else
        assert_not_equals "0" "$result" "Quiet mode should fail when OpenSSL is not available"
    fi
    
    # Verify output is empty in quiet mode
    assert_equals "" "$output" "Quiet mode should produce no output"
    
    # Double-check the regular command output for comparison
    local verbose_output
    verbose_output=$(D secret available 2>&1)
    assert_not_equals "" "$verbose_output" "Regular mode should produce output unlike quiet mode"
}

# Test availability check invalid arguments
test_secret_available_invalid_args() {
    # Test with a single invalid argument
    local output
    output=$(D secret available --invalid-arg 2>&1)
    local result=$?
    
    # Verify error handling for invalid arguments
    assert_not_equals "0" "$result" "Command should fail with invalid argument"
    assert_contains "$output" "Unknown argument" "Should indicate unknown argument"
    assert_contains "$output" "invalid-arg" "Should mention the specific invalid argument"
    
    # Test with multiple invalid arguments
    local output2
    output2=$(D secret available --bad-flag --another-bad-flag 2>&1)
    local result2=$?
    
    # Verify error handling for multiple invalid arguments
    assert_not_equals "0" "$result2" "Command should fail with multiple invalid arguments"
    assert_contains "$output2" "Unknown argument" "Should indicate unknown argument"
    assert_contains "$output2" "bad-flag" "Should mention at least one of the invalid arguments"
    
    # Test with mix of valid and invalid arguments
    local output3
    output3=$(D secret available --quiet --invalid-mix 2>&1)
    local result3=$?
    
    # Verify error handling for mixed arguments
    assert_not_equals "0" "$result3" "Command should fail with mixed valid/invalid arguments"
    assert_contains "$output3" "Unknown argument" "Should indicate unknown argument"
    assert_contains "$output3" "invalid-mix" "Should mention the specific invalid argument"
}

# Test that secrets directory information is shown
test_secret_available_shows_directory_info() {
    # Set a custom secrets directory for this test
    local custom_dir="$TEST_WORKSPACE/custom_secrets_dir"
    mkdir -p "$custom_dir"
    
    # Run the command with the custom directory
    local output
    output=$(SECRETS_DIR="$custom_dir" D secret available 2>&1)
    local result=$?
    
    # Verify command succeeded
    assert_equals "0" "$result" "Command should succeed with custom secrets directory"
    
    # Verify directory information is displayed correctly
    assert_contains "$output" "Secrets Directory" "Should have a section for secrets directory"
    assert_contains "$output" "$custom_dir" "Should display the custom directory path"
    
    # Verify the default secrets directory is different
    local default_output
    default_output=$(D secret available 2>&1)
    assert_contains "$default_output" "$SECRETS_DIR" "Default output should show the default secrets directory"
    
    # Verify directory exists message
    if [ -d "$custom_dir" ]; then
        assert_contains "$output" "exists\|found" "Should indicate directory exists"
    else
        assert_contains "$output" "does not exist\|not found" "Should indicate directory does not exist"
    fi
}
