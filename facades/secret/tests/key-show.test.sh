#!/bin/bash

# Test for the 'secret key-show' command

# Setup function - runs before each test
setup_test() {
    TEST_SECRET_DIR="$(D --quiet secret function sdk_fac_sec_get_secrets_dir)"
}

# Test key-show command with no key configured
test_secret_key_show_no_key_configured() {
    # Ensure no key file exists
    rm -f "$SECRETS_DIR/.key"
    
    # Attempt to show a non-existent key
    local output
    output=$(D secret key-show 2>&1)
    local result=$?
    
    # Verify command fails with appropriate error message
    assert_not_equals "0" "$result" "Key-show should fail when no key is configured"
    assert_contains "$output" "No encryption key configured\|key not found\|no key" "Should indicate no key configured"
    assert_contains "$output" "init\|key-set\|configure" "Should suggest how to configure a key"
    
    # Verify no sensitive data is leaked in error message
    assert_not_contains "$output" "[0-9a-f]\{16,\}" "Error message should not contain hex key fragments"
}

# Test key-show command with configured key
test_secret_key_show_with_configured_key() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # We're testing that key-show works with openssl available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # First set a key
    local test_key="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local set_output
    set_output=$(D secret key-set <<< "$test_key" 2>&1)
    
    # Verify key was set successfully
    assert_equals "0" "$?" "Key should be set successfully"
    
    # Now show the key
    local show_output
    show_output=$(D secret key-show 2>&1)
    
    # Verify key display works correctly
    assert_equals "0" "$?" "Key-show should succeed with configured key"
    assert_contains "$show_output" "Current encryption key" "Should indicate current encryption key"
    assert_contains "$show_output" "$test_key" "Should display the actual key"
}

# Test key-show command output format
test_secret_key_show_output_format() {
    # Check if OpenSSL is available
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # We're testing that key-show format works with openssl available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Set a key
    local test_key="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    local set_output
    set_output=$(D secret key-set <<< "$test_key" 2>&1)
    
    # Verify key was set successfully
    assert_equals "0" "$?" "Key should be set successfully"
    
    # Show the key and check format
    local show_output
    show_output=$(D secret key-show 2>&1)
    
    # Verify key display works correctly
    assert_equals "0" "$?" "Key-show should succeed with configured key"
    
    # Should have a proper header line
    echo "$show_output" | grep -q "Current encryption key"
    assert_equals "0" "$?" "Should have header indicating current encryption key"
    
    # Should have the key on a separate line
    local key_line=$(echo "$show_output" | grep "$test_key")
    assert_not_equals "" "$key_line" "Should display the key on its own line"
    
    # Should have at least 2 lines (header + key)
    local line_count=$(echo "$show_output" | wc -l | tr -d ' ')
    assert_not_equals "1" "$line_count" "Should have multiple lines (header + key)"
}

# Test key-show command after adding a secret (auto-generated key)
test_secret_key_show_after_auto_generated_key() {
    # Check if OpenSSL is available
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # We're testing auto-generated keys with openssl available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Add a secret which should auto-generate a key
    local add_output
    add_output=$(D secret add <<< $'AUTO_KEY_SECRET\nauto_key_value' 2>&1)
    
    # Verify secret was added successfully
    assert_equals "0" "$?" "Secret should be added successfully with auto-generated key"
    
    # Now try to show the key
    local show_output
    show_output=$(D secret key-show 2>&1)
    
    # Verify key display works correctly
    assert_equals "0" "$?" "Key-show should succeed with auto-generated key"
    assert_contains "$show_output" "Current encryption key" "Should show header for auto-generated key"
    
    # Extract the key from the last line
    local key_line=$(echo "$show_output" | tail -n 1)
    
    # Key should be a valid 64-character hex string
    assert_valid_hex_key "$key_line" 64 "Auto-generated key should be valid 64-character hex"
}

# Test key-show command displays complete key
test_secret_key_show_displays_complete_key() {
    # Check if OpenSSL is available
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # We're testing complete key display with openssl available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Set a known key with specific pattern for verification
    local known_key="aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899"
    local set_output
    set_output=$(D secret key-set <<< "$known_key" 2>&1)
    
    # Verify key was set successfully
    assert_equals "0" "$?" "Key should be set successfully"
    
    # Show the key
    local show_output
    show_output=$(D secret key-show 2>&1)
    
    # Verify key display works correctly
    assert_equals "0" "$?" "Key-show should succeed with configured key"
    assert_contains "$show_output" "Current encryption key" "Should indicate current encryption key"
    
    # Verify the complete key is shown
    assert_contains "$show_output" "$known_key" "Should display the complete key"
    
    # Check that the key starts and ends with the expected patterns
    assert_contains "$show_output" "aabbccdd" "Should show beginning of key"
    assert_contains "$show_output" "66778899" "Should show end of key"
    
    # Verify no truncation occurred
    local key_line=$(echo "$show_output" | grep "$known_key")
    assert_contains "$key_line" "$known_key" "Should show complete key without truncation"
}

# Test key-show command does not show sensitive data in error cases
test_secret_key_show_error_handling() {
    # First ensure no key exists to test error handling
    D secret key-reset --force 2>&1
    
    # Test the error message when no key is configured
    local output
    output=$(D secret key-show 2>&1)
    
    # Verify error handling
    assert_not_equals "0" "$?" "Should fail when no key configured"
    
    # Error message should not contain any sensitive data or partial keys
    assert_not_contains "$output" "[0-9a-f]\{32\}" "Error message should not contain hex key fragments"
    assert_contains "$output" "No encryption key configured\|key not found\|no key" "Should provide clear error message"
}

# Test key-show command with different key lengths (edge cases)
test_secret_key_show_different_key_lengths() {
    # Check if OpenSSL is available
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # We're testing edge cases with openssl available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Set a short key (should be allowed with confirmation during set)
    local short_key="short_key"
    local set_output
    set_output=$(D secret key-set <<< $'short_key\ny' 2>&1)
    
    # Verify key was set successfully despite being short
    assert_equals "0" "$?" "Short key should be set successfully with confirmation"
    
    # Show the short key
    local show_output
    show_output=$(D secret key-show 2>&1)
    
    # Verify key display works correctly
    assert_equals "0" "$?" "Key-show should succeed with non-standard key"
    assert_contains "$show_output" "Current encryption key" "Should show header for non-standard key"
    assert_contains "$show_output" "$short_key" "Should display non-standard key length"
}
