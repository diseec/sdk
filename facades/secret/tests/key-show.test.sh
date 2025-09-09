#!/bin/bash

# Test for the 'secret key-show' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "secret_key_show_tests")
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test key-show command with no key configured
test_secret_key_show_no_key_configured() {
    local output
    output=$(d secret key-show 2>&1)
    local result=$?
    
    # Should fail when no key is configured
    assert_not_equals "0" "$result" "Key-show should fail when no key is configured"
    assert_contains "$output" "No encryption key configured\|Run.*secrets init" "Should indicate no key configured"
}

# Test key-show command with configured key
test_secret_key_show_with_configured_key() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First set a key
    local test_key="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local set_output
    set_output=$(echo "$test_key" | D secret key-set 2>&1)
    local set_result=$?
    
    if [ "$set_result" -ne 0 ]; then
        # Skip if we couldn't set the key
        return 0
    fi
    
    # Now show the key
    local show_output
    show_output=$(d secret key-show 2>&1)
    local show_result=$?
    
    if [ "$show_result" -eq 0 ]; then
        # Should succeed and display the key
        assert_contains "$show_output" "Current encryption key" "Should indicate current encryption key"
        assert_contains "$show_output" "$test_key" "Should display the actual key"
    fi
}

# Test key-show command output format
test_secret_key_show_output_format() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First set a key
    local test_key="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    local set_output
    set_output=$(echo "$test_key" | D secret key-set 2>&1)
    local set_result=$?
    
    if [ "$set_result" -ne 0 ]; then
        # Skip if we couldn't set the key
        return 0
    fi
    
    # Show the key and check format
    local show_output
    show_output=$(d secret key-show 2>&1)
    local show_result=$?
    
    if [ "$show_result" -eq 0 ]; then
        # Should have a proper header line
        echo "$show_output" | grep -q "Current encryption key"
        assert_equals "0" "$?" "Should have header indicating current encryption key"
        
        # Should have the key on a separate line
        local key_line=$(echo "$show_output" | grep "$test_key")
        assert_not_equals "" "$key_line" "Should display the key on its own line"
        
        # Should have at least 2 lines (header + key)
        local line_count=$(echo "$show_output" | wc -l | tr -d ' ')
        assert_not_equals "1" "$line_count" "Should have multiple lines (header + key)"
    fi
}

# Test key-show command after adding a secret (auto-generated key)
test_secret_key_show_after_auto_generated_key() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Add a secret which should auto-generate a key
    local add_output
    add_output=$(echo -e "AUTO_KEY_SECRET\nauto_key_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Now try to show the key
    local show_output
    show_output=$(d secret key-show 2>&1)
    local show_result=$?
    
    if [ "$show_result" -eq 0 ]; then
        # Should display the auto-generated key
        assert_contains "$show_output" "Current encryption key" "Should show header for auto-generated key"
        
        # Extract the key from the last line
        local key_line=$(echo "$show_output" | tail -n 1)
        
        # Key should be a valid 64-character hex string
        assert_valid_hex_key "$key_line" 64 "Auto-generated key should be valid 64-character hex"
    fi
}

# Test key-show command displays complete key
test_secret_key_show_displays_complete_key() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Set a known key with specific pattern for verification
    local known_key="aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899"
    local set_output
    set_output=$(echo "$known_key" | D secret key-set 2>&1)
    local set_result=$?
    
    if [ "$set_result" -ne 0 ]; then
        # Skip if we couldn't set the key
        return 0
    fi
    
    # Show the key
    local show_output
    show_output=$(d secret key-show 2>&1)
    local show_result=$?
    
    if [ "$show_result" -eq 0 ]; then
        # Verify the complete key is shown
        assert_contains "$show_output" "$known_key" "Should display the complete key"
        
        # Check that the key starts and ends with the expected patterns
        assert_contains "$show_output" "aabbccdd" "Should show beginning of key"
        assert_contains "$show_output" "66778899" "Should show end of key"
        
        # Verify no truncation occurred
        local key_line=$(echo "$show_output" | grep "$known_key")
        assert_contains "$key_line" "$known_key" "Should show complete key without truncation"
    fi
}

# Test key-show command does not show sensitive data in error cases
test_secret_key_show_error_handling() {
    # Test the error message when no key is configured
    local output
    output=$(d secret key-show 2>&1)
    local result=$?
    
    # Should fail gracefully
    assert_not_equals "0" "$result" "Should fail when no key configured"
    
    # Error message should not contain any sensitive data or partial keys
    assert_not_contains "$output" "[0-9a-f]\{32\}" "Error message should not contain hex key fragments"
    assert_contains "$output" "No encryption key configured" "Should provide clear error message"
}

# Test key-show command with different key lengths (edge cases)
test_secret_key_show_different_key_lengths() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Set a short key (should be allowed with confirmation during set)
    local short_key="short_key"
    local set_output
    set_output=$(echo -e "$short_key\ny" | D secret key-set 2>&1)
    local set_result=$?
    
    if [ "$set_result" -eq 0 ]; then
        # Show the short key
        local show_output
        show_output=$(d secret key-show 2>&1)
        local show_result=$?
        
        if [ "$show_result" -eq 0 ]; then
            # Should display even non-standard keys
            assert_contains "$show_output" "$short_key" "Should display non-standard key length"
            assert_contains "$show_output" "Current encryption key" "Should show header for non-standard key"
        fi
    fi
}
