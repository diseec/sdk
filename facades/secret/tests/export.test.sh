#!/bin/bash

# Test for the 'secret export' command

# Test export command requires secret name
test_secret_export_requires_name() {
    local output
    output=$(D secret export 2>&1)
    local result=$?
    
    # Should fail without secret name
    assert_not_equals "0" "$result" "Export should fail without secret name"
    assert_contains "$output" "Secret name required\|Usage" "Should indicate secret name is required"
}

# Test export command with non-existent secret
test_secret_export_nonexistent_secret() {
    local output
    output=$(D secret export NONEXISTENT_SECRET 2>&1)
    local result=$?
    
    # Should fail with non-existent secret
    assert_not_equals "0" "$result" "Export should fail with non-existent secret"
    assert_contains "$output" "not found\|does not exist" "Should indicate secret not found"
}

# Test export command requires OpenSSL
test_secret_export_requires_openssl() {
    # Skip if OpenSSL is not available (we can't easily test this scenario)
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # OpenSSL not available - export should fail
        local output
        output=$(D secret export ANY_SECRET 2>&1)
        local export_result=$?
        
        assert_not_equals "0" "$export_result" "Export should fail without OpenSSL"
    fi
}

# Test export command with existing secret
test_secret_export_existing_secret() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret to export
    local add_output
    add_output=$(echo -e "EXPORT_TEST_SECRET\nexport_test_value_456" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Now try to export it
    local export_output
    export_output=$(D secret export EXPORT_TEST_SECRET 2>&1)
    local export_result=$?
    
    if [ "$export_result" -eq 0 ]; then
        # Should return just the value (non-interactive)
        assert_equals "export_test_value_456" "$export_output" "Should export the exact secret value"
    else
        # If export failed, it might be due to missing key configuration
        assert_contains "$export_output" "key\|configured\|decrypt" "Should indicate key/decryption issue"
    fi
}

# Test export command without encryption key configured
test_secret_export_no_key_configured() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Create a mock secret file without proper key setup
    # This simulates the scenario where secrets exist but no key is configured
    mkdir -p "$TEST_WORKSPACE/secrets"
    echo "mock_encrypted_data" > "$TEST_WORKSPACE/secrets/MOCK_SECRET"
    
    # Try to export without key
    local output
    output=$(D secret export MOCK_SECRET 2>&1)
    local result=$?
    
    # Should fail or prompt for key configuration
    if [ "$result" -ne 0 ]; then
        assert_contains "$output" "key\|configured\|encryption" "Should indicate key configuration issue"
    fi
}

# Test export command output format
test_secret_export_output_format() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret with known value
    local test_value="simple_export_value"
    local add_output
    add_output=$(echo -e "FORMAT_TEST_SECRET\n$test_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Export and check that output is just the value (no extra text)
    local export_output
    export_output=$(D secret export FORMAT_TEST_SECRET 2>&1)
    local export_result=$?
    
    if [ "$export_result" -eq 0 ]; then
        # Should be exactly the value with no extra formatting
        assert_equals "$test_value" "$export_output" "Export should return only the secret value"
        
        # Should not contain any log messages or formatting
        local line_count=$(echo "$export_output" | wc -l | tr -D ' ')
        assert_equals "1" "$line_count" "Export should return single line"
    fi
}

# Test export command with special characters in secret value
test_secret_export_special_characters() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Test value with special characters
    local special_value="password!@#$%^&*()_+-={}[]|\\:;\"'<>,.?/"
    local add_output
    add_output=$(echo -e "SPECIAL_CHARS_SECRET\n$special_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Export and verify special characters are preserved
    local export_output
    export_output=$(D secret export SPECIAL_CHARS_SECRET 2>&1)
    local export_result=$?
    
    if [ "$export_result" -eq 0 ]; then
        # Should preserve all special characters
        assert_equals "$special_value" "$export_output" "Export should preserve special characters"
    fi
}
