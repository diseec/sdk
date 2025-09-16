#!/bin/bash

# Test for the 'secret available' command
# Setup function - runs before each test
setup_test() {
    TEST_SECRET_DIR="$(D secret function sdk_fac_sec_get_secrets_dir)"
}

# Test availability check basic functionality
test_secret_available_basic() {
    local output
    output=$(D secret available)
    local result=$?
    
    # Command should succeed regardless of OpenSSL availability
    assert_equals "0" "$result" "Basic availability check should always return success"
    
    # Updated assertions based on actual output format
    assert_contains "$output" "Checking secrets system availability" "Should show checking message"
    assert_contains "$output" "Secrets system is available" "Should indicate success"
    assert_contains "$output" "Secrets Directory" "Should mention secrets directory"
    assert_contains "$output" "Encryption" "Should mention encryption"
}

# Test availability check with quiet flag
test_secret_available_quiet() {
    # Determine if OpenSSL is actually available on the system
    local openssl_available=0
    if ! command -v openssl >/dev/null; then
        openssl_available=1
    fi
    
    # Test with quiet flag
    local output
    output=$(D secret available --quiet)
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
    verbose_output=$(D secret available)
    assert_not_equals "" "$verbose_output" "Regular mode should produce output unlike quiet mode"
}
