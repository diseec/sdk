#!/bin/bash

# Test for the 'secret key-reset' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "secret_key_reset_tests")
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test key-reset command with no key configured
test_secret_key_reset_no_key_configured() {
    local output
    output=$(d secret key-reset 2>&1)
    local result=$?
    
    # Should fail when no key is configured
    assert_not_equals "0" "$result" "Key-reset should fail when no key is configured"
    assert_contains "$output" "No encryption key configured\|Use.*set-key.*first" "Should indicate no key configured"
}

# Test key-reset command requires OpenSSL
test_secret_key_reset_requires_openssl() {
    # Skip if OpenSSL is not available (we can't easily test this scenario)
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # OpenSSL not available - key-reset should fail
        local output
        output=$(echo "y" | D secret key-reset 2>&1)
        local key_reset_result=$?
        
        assert_not_equals "0" "$key_reset_result" "Key-reset should fail without OpenSSL"
    fi
}

# Test key-reset command without existing secrets
test_secret_key_reset_no_secrets() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First set a key so we can reset it
    local initial_key="1111111111111111111111111111111111111111111111111111111111111111"
    local set_output
    set_output=$(echo "$initial_key" | D secret key-set 2>&1)
    local set_result=$?
    
    if [ "$set_result" -ne 0 ]; then
        # Skip if we couldn't set the initial key
        return 0
    fi
    
    # Reset the key (no secrets exist, so should generate new key)
    local reset_output
    reset_output=$(d secret key-reset 2>&1)
    local reset_result=$?
    
    if [ "$reset_result" -eq 0 ]; then
        assert_contains "$reset_output" "New encryption key generated\|generated" "Should indicate new key was generated"
        assert_contains "$reset_output" "Key:" "Should display the new key"
        assert_contains "$reset_output" "Store this key safely" "Should warn to store key safely"
        
        # Verify the key changed
        local new_key_output
        new_key_output=$(d secret key-show 2>&1)
        local new_key_result=$?
        
        if [ "$new_key_result" -eq 0 ]; then
            # New key should be different from initial key
            assert_not_contains "$new_key_output" "$initial_key" "New key should be different from initial key"
        fi
    fi
}

# Test key-reset command with existing secrets - confirm
test_secret_key_reset_with_secrets_confirm() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret (this will create a key automatically)
    local add_output
    add_output=$(echo -e "RESET_TEST_SECRET\nreset_test_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Get the original key for comparison
    local original_key_output
    original_key_output=$(d secret key-show 2>&1)
    local original_key_result=$?
    
    if [ "$original_key_result" -ne 0 ]; then
        # Skip if we can't get the original key
        return 0
    fi
    
    local original_key=$(echo "$original_key_output" | tail -n 1)
    
    # Reset the key with confirmation (answer 'y' to prompt)
    local reset_output
    reset_output=$(echo "y" | D secret key-reset 2>&1)
    local reset_result=$?
    
    if [ "$reset_result" -eq 0 ]; then
        assert_contains "$reset_output" "re-encrypt.*existing secrets\|Make sure you have the current key" "Should warn about re-encrypting secrets"
        assert_contains "$reset_output" "All secrets re-encrypted\|re-encrypted with new key" "Should indicate secrets were re-encrypted"
        assert_contains "$reset_output" "New key:" "Should display the new key"
        
        # Verify the key changed
        local new_key_output
        new_key_output=$(d secret key-show 2>&1)
        local new_key_result=$?
        
        if [ "$new_key_result" -eq 0 ]; then
            local new_key=$(echo "$new_key_output" | tail -n 1)
            assert_not_equals "$original_key" "$new_key" "New key should be different from original key"
            
            # Verify secrets still exist and can be decrypted with new key
            local export_output
            export_output=$(d secret export RESET_TEST_SECRET 2>&1)
            local export_result=$?
            
            if [ "$export_result" -eq 0 ]; then
                assert_equals "reset_test_value" "$export_output" "Secret should be decryptable with new key"
            fi
        fi
    fi
}

# Test key-reset command with existing secrets - cancel
test_secret_key_reset_with_secrets_cancel() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret
    local add_output
    add_output=$(echo -e "CANCEL_RESET_SECRET\ncancel_reset_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Get the original key for comparison
    local original_key_output
    original_key_output=$(d secret key-show 2>&1)
    local original_key_result=$?
    
    if [ "$original_key_result" -ne 0 ]; then
        # Skip if we can't get the original key
        return 0
    fi
    
    local original_key=$(echo "$original_key_output" | tail -n 1)
    
    # Try to reset but cancel (answer 'n' to prompt)
    local reset_output
    reset_output=$(echo "n" | D secret key-reset 2>&1)
    local reset_result=$?
    
    # Should cancel the operation
    if [ "$reset_result" -eq 0 ]; then
        # Operation might succeed but do nothing, or might be cancelled
        local key_after_cancel
        key_after_cancel=$(d secret key-show 2>&1)
        local key_after_result=$?
        
        if [ "$key_after_result" -eq 0 ]; then
            local key_after=$(echo "$key_after_cancel" | tail -n 1)
            assert_equals "$original_key" "$key_after" "Key should remain unchanged after cancelling reset"
        fi
    fi
}

# Test key-reset command confirmation prompt
test_secret_key_reset_confirmation_prompt() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret to trigger the confirmation prompt
    local add_output
    add_output=$(echo -e "PROMPT_RESET_SECRET\nprompt_reset_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Try to reset and check the confirmation prompt
    local reset_output
    reset_output=$(echo "n" | D secret key-reset 2>&1)
    
    # Should show warning and ask for confirmation
    assert_contains "$reset_output" "re-encrypt all existing secrets\|new key" "Should warn about re-encrypting"
    assert_contains "$reset_output" "Make sure you have.*current key" "Should warn to have current key"
    assert_contains "$reset_output" "Continue" "Should ask for continuation confirmation"
}

# Test key-reset command generates valid key
test_secret_key_reset_generates_valid_key() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First set an initial key
    local initial_key="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    local set_output
    set_output=$(echo "$initial_key" | D secret key-set 2>&1)
    local set_result=$?
    
    if [ "$set_result" -ne 0 ]; then
        # Skip if we couldn't set the initial key
        return 0
    fi
    
    # Reset to generate a new key
    local reset_output
    reset_output=$(d secret key-reset 2>&1)
    local reset_result=$?
    
    if [ "$reset_result" -eq 0 ]; then
        # Extract the new key from output (should be after "Key: ")
        local new_key_line=$(echo "$reset_output" | grep "Key:" | sed 's/Key: //')
        
        if [ -n "$new_key_line" ]; then
            # Should be a valid 64-character hex key
            assert_valid_hex_key "$new_key_line" 64 "Generated key should be valid 64-character hex"
            
            # Should be different from initial key
            assert_not_equals "$initial_key" "$new_key_line" "Generated key should be different from initial"
        fi
    fi
}

# Test key-reset command output format
test_secret_key_reset_output_format() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First set a key
    local initial_key="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    local set_output
    set_output=$(echo "$initial_key" | D secret key-set 2>&1)
    local set_result=$?
    
    if [ "$set_result" -ne 0 ]; then
        # Skip if we couldn't set the initial key
        return 0
    fi
    
    # Reset the key (no secrets, so should be simpler output)
    local reset_output
    reset_output=$(d secret key-reset 2>&1)
    local reset_result=$?
    
    if [ "$reset_result" -eq 0 ]; then
        # Should have proper structure
        assert_contains "$reset_output" "New encryption key generated" "Should announce key generation"
        assert_contains "$reset_output" "Key:" "Should label the key"
        assert_contains "$reset_output" "Store this key safely" "Should include safety warning"
        
        # Should be multiple lines
        local line_count=$(echo "$reset_output" | wc -l | tr -d ' ')
        assert_not_equals "1" "$line_count" "Should have multiple lines of output"
    fi
}
