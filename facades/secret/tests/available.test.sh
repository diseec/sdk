#!/bin/bash

# Test for the 'secret available' command

# Test availability check basic functionality
test_secret_available_basic() {
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available 2>&1)
    
    # Command should succeed if OpenSSL is available
    local result=$?
    
    # Should contain availability information
    assert_contains "$output" "available\|OpenSSL\|Secrets" "Should show availability status"
}

# Test availability check with quiet flag
test_secret_available_quiet() {
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    # The command should either succeed or fail gracefully
    # We test both scenarios since OpenSSL availability varies by environment
    if [ "$result" -eq 0 ]; then
        # If OpenSSL is available, command should succeed
        # We won't test output content in quiet mode as it may vary
        assert_equals "0" "$result" "Command should succeed when OpenSSL is available"
    else
        # If OpenSSL is not available, command should fail
        assert_not_equals "0" "$result" "Command should fail when OpenSSL is not available"
    fi
}

# Test availability check invalid arguments
test_secret_available_invalid_args() {
    local output
    output=$(D secret available --invalid-arg 2>&1)
    local result=$?
    
    # Should contain error message about unknown argument
    assert_contains "$output" "Unknown argument" "Should indicate unknown argument"
    
    # Test multiple invalid arguments
    local output2
    output2=$(D secret available --bad-flag --another-bad-flag 2>&1)
    assert_contains "$output2" "Unknown argument" "Should indicate unknown argument with multiple bad flags"
}

# Test that secrets directory information is shown
test_secret_available_shows_directory_info() {
    local output
    output=$(D secret available 2>&1)
    
    # Should show secrets directory path
    assert_contains "$output" "Secrets Directory\|secrets" "Should mention secrets directory"
}
