#!/bin/bash

# Test for the 'secret key-reset' command
# Setup function - runs before each test
setup_test() {
    TEST_SECRET_DIR="$(D --quiet secret function sdk_fac_sec_get_secrets_dir)"
}

# Test key-reset command with no key configured
test_secret_key_reset_no_key_configured() {
    # Ensure no key exists by using the CLI
    D secret key-reset --force > /dev/null 2>&1 || true
    
    # Attempt to reset a non-existent key
    local output
    output=$(D secret key-reset 2>&1)
    
    # Verify command fails with appropriate error message
    assert_not_equals "0" "$?" "Key-reset should fail when no key is configured"
    assert_contains "$output" "No encryption key configured\|no key\|key not found" "Should indicate no key configured"
    assert_contains "$output" "set-key\|key-set" "Should mention key-set command in error message"
}


# Test key-reset command without existing secrets
test_secret_key_reset_no_secrets() {
    # Set an initial key using the CLI
    local initial_key="1111111111111111111111111111111111111111111111111111111111111111"
    D secret key-set <<< "$initial_key" > /dev/null 2>&1
    
    # Reset the key (no secrets exist, so should simply generate new key)
    local reset_output
    reset_output=$(D secret key-reset 2>&1)
    
    # Verify reset succeeded
    assert_equals "0" "$?" "Key-reset should succeed with no secrets"
    assert_contains "$reset_output" "New encryption key generated\|generated" "Should indicate new key was generated"
    assert_contains "$reset_output" "Key:" "Should display the new key"
    assert_contains "$reset_output" "Store this key safely" "Should warn to store key safely"
    
    # Verify new key is different from initial key
    local new_key_output
    new_key_output=$(D secret key-show 2>&1)
    
    assert_equals "0" "$?" "Should be able to show the new key"
    assert_not_contains "$new_key_output" "$initial_key" "New key should be different from initial key"
}

# Test key-reset command with existing secrets - confirm
test_secret_key_reset_with_secrets_confirm() {
    # First add a secret (this will create a key automatically)
    local secret_name="RESET_TEST_SECRET"
    local secret_value="reset_test_value"
    local add_output
    add_output=$(D secret add <<< $'RESET_TEST_SECRET\nreset_test_value' 2>&1)
    
    # Verify secret was added successfully
    assert_equals "0" "$?" "Secret should be added successfully"
    
    # Get the original key for comparison
    local original_key_output
    original_key_output=$(D secret key-show 2>&1)
    
    # Verify we can get the original key
    assert_equals "0" "$?" "Should be able to show the original key"
    
    # Extract the original key (last line of output)
    local original_key=$(echo "$original_key_output" | tail -n 1)
    
    # Reset the key with confirmation
    local reset_output
    reset_output=$(D secret key-reset <<< "y" 2>&1)
    
    # Verify reset succeeded
    assert_equals "0" "$?" "Key-reset should succeed with confirmation"
    assert_contains "$reset_output" "re-encrypt.*existing secrets\|re-encrypting" "Should indicate re-encryption of secrets"
    assert_contains "$reset_output" "All secrets re-encrypted\|re-encrypted with new key" "Should confirm re-encryption completed"
    assert_contains "$reset_output" "New key:" "Should display the new key"
    
    # Verify the key changed
    local new_key_output
    new_key_output=$(D secret key-show 2>&1)
    
    assert_equals "0" "$?" "Should be able to show the new key"
    local new_key=$(echo "$new_key_output" | tail -n 1)
    assert_not_equals "$original_key" "$new_key" "New key should be different from original key"
    
    # Verify secret still exists and can be decrypted with new key
    local export_output
    export_output=$(D secret export "$secret_name" 2>&1)
    
    assert_equals "0" "$?" "Should be able to export secret with new key"
    assert_equals "$secret_value" "$export_output" "Secret value should be preserved after key reset"
}

# Test key-reset command with existing secrets - cancel
test_secret_key_reset_with_secrets_cancel() {
    # Add a test secret
    local secret_name="CANCEL_RESET_SECRET"
    local secret_value="cancel_reset_value"
    local add_output
    add_output=$(D secret add <<< $'CANCEL_RESET_SECRET\ncancel_reset_value' 2>&1)
    
    # Verify secret was added successfully
    assert_equals "0" "$?" "Secret should be added successfully"
    
    # Get the original key for comparison
    local original_key_output
    original_key_output=$(D secret key-show 2>&1)
    
    # Verify we can get the original key
    assert_equals "0" "$?" "Should be able to show the original key"
    
    # Extract the original key
    local original_key=$(echo "$original_key_output" | tail -n 1)
    
    # Try to reset but cancel
    local reset_output
    reset_output=$(D secret key-reset <<< "n" 2>&1)
    
    # Verify operation was cancelled
    assert_equals "0" "$?" "Key-reset should exit cleanly when cancelled"
    assert_contains "$reset_output" "cancelled\|aborted\|Cancelled" "Should indicate operation was cancelled"
    
    # Verify key is still the same
    local key_after_cancel
    key_after_cancel=$(D secret key-show 2>&1)
    
    assert_equals "0" "$?" "Should be able to show key after cancelled reset"
    local key_after=$(echo "$key_after_cancel" | tail -n 1)
    assert_equals "$original_key" "$key_after" "Key should remain unchanged after cancelling reset"
    
    # Verify secret is still accessible with original key
    local export_output
    export_output=$(D secret export "$secret_name" 2>&1)
    
    assert_equals "0" "$?" "Should be able to export secret with original key"
    assert_equals "$secret_value" "$export_output" "Secret should be accessible with original key"
}

# Test key-reset command confirmation prompt
test_secret_key_reset_confirmation_prompt() {
    # Add a test secret to trigger the confirmation prompt
    local secret_name="PROMPT_RESET_SECRET"
    local secret_value="prompt_reset_value"
    local add_output
    add_output=$(D secret add <<< $'PROMPT_RESET_SECRET\nprompt_reset_value' 2>&1)
    
    # Verify secret was added successfully
    assert_equals "0" "$?" "Secret should be added successfully"
    
    # Capture reset output to check the confirmation prompt
    local reset_output
    reset_output=$(D secret key-reset <<< "n" 2>&1)
    
    # Verify the prompt content
    assert_contains "$reset_output" "existing secrets\|all secrets" "Should warn about existing secrets"
    assert_contains "$reset_output" "re-encrypt\|new key" "Should mention re-encryption with new key"
    assert_contains "$reset_output" "current key\|existing key" "Should mention current/existing key"
    assert_contains "$reset_output" "Continue\|proceed\|confirm" "Should ask for confirmation to proceed"
    assert_contains "$reset_output" "y/n\|Y/N\|yes/no" "Should provide confirmation options"
    
    # Verify secret file wasn't affected
    local export_output
    export_output=$(D secret export "$secret_name" 2>&1)
    
    assert_equals "0" "$?" "Secret should still be accessible after cancelled reset"
    assert_equals "$secret_value" "$export_output" "Secret value should be unchanged after cancelled reset"
}

# Test key-reset command generates valid key
test_secret_key_reset_generates_valid_key() {
    # Set an initial key
    local initial_key="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    D secret key-set <<< "$initial_key" > /dev/null 2>&1
    
    # Reset to generate a new key
    local reset_output
    reset_output=$(D secret key-reset 2>&1)
    
    # Verify reset succeeded
    assert_equals "0" "$?" "Key-reset should succeed with no secrets"
    assert_contains "$reset_output" "New encryption key generated\|generated" "Should indicate new key was generated"
    
    # Extract the new key from output (should be after "Key: ")
    local new_key_line=$(echo "$reset_output" | grep -o "Key:.*" | sed 's/Key: //')
    
    # Verify new key is valid
    assert_not_equals "" "$new_key_line" "Should extract non-empty key from output"
    
    # Check key length - should be 64 hex characters (32 bytes)
    local key_length=${#new_key_line}
    assert_equals "64" "$key_length" "Generated key should be 64 characters long"
    
    # Check key is valid hex (only contains 0-9, a-f, A-F)
    local valid_hex=1
    if ! [[ "$new_key_line" =~ ^[0-9a-fA-F]+$ ]]; then
        valid_hex=0
    fi
    assert_equals "1" "$valid_hex" "Generated key should contain only valid hex characters"
    
    # Verify key is different from initial key
    assert_not_equals "$initial_key" "$new_key_line" "Generated key should be different from initial key"
    
    # Verify key-show also works with the new key
    local key_show_output
    key_show_output=$(D secret key-show 2>&1)
    
    assert_equals "0" "$?" "Should be able to show the new key"
    assert_contains "$key_show_output" "$new_key_line" "key-show should display the same key that was generated"
}

# Test key-reset command output format
test_secret_key_reset_output_format() {
    # Set an initial key
    local initial_key="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    D secret key-set <<< "$initial_key" > /dev/null 2>&1
    
    # Reset the key
    local reset_output
    reset_output=$(D secret key-reset 2>&1)
    
    # Verify reset succeeded
    assert_equals "0" "$?" "Key-reset should succeed"
    
    # Verify output formatting
    assert_contains "$reset_output" "New encryption key generated" "Should announce key generation"
    assert_contains "$reset_output" "Key:" "Should label the key"
    assert_contains "$reset_output" "Store this key safely" "Should include safety warning"
    
    # Verify proper formatting with multiple lines
    local line_count=$(echo "$reset_output" | wc -l | tr -d ' ')
    assert_greater_than "$line_count" "2" "Should have at least 3 lines of output"
    
    # Verify the key line format
    local key_line=$(echo "$reset_output" | grep -o "Key:.*")
    assert_not_equals "" "$key_line" "Should contain a line starting with 'Key:'"
    
    # Verify key is displayed on a separate line from warnings
    local key_and_warning=$(echo "$reset_output" | grep -o "Key:.*Store this key safely")
    assert_equals "" "$key_and_warning" "Key and warning should be on separate lines"
    
    # Verify we can extract a 64-character hex key from the output
    local extracted_key=$(echo "$reset_output" | grep -o "Key:.*" | sed 's/Key: //')
    local key_length=${#extracted_key}
    assert_equals "64" "$key_length" "Should extract a 64-character key from output"
}
