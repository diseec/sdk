#!/bin/bash

# Test for the 'secret print' command
# Setup function - runs before each test
setup_test() {
    TEST_SECRET_DIR="$(D --quiet secret function sdk_fac_sec_get_secrets_dir)"
}

# Test print command with no secrets
test_secret_print_no_secrets() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # Skip test if OpenSSL not available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Ensure no secrets exist
    D secret key-reset --force 2>&1 || true
    
    local output
    output=$(D secret print 2>&1)
    
    # Should succeed but indicate no secrets found
    assert_equals "0" "$?" "Print command should succeed with no secrets"
    assert_contains "$output" "No secrets found\|No secrets\|0 secrets" "Should indicate no secrets found"
}

# Test print command with single secret
test_secret_print_single_secret() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # Skip test if OpenSSL not available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # First add a secret
    D secret add <<< $'PRINT_TEST_SECRET\nprint_test_value'
    
    # Verify secret was added successfully
    assert_equals "0" "$?" "Should be able to add a secret for testing"
    
    # Now print all secrets
    local print_output
    print_output=$(D secret print)

    # Should succeed and contain the secret
    assert_equals "0" "$?" "Print command should succeed with single secret"
    assert_contains "$print_output" "PRINT_TEST_SECRET" "Should show secret name"
    assert_contains "$print_output" "print_test_value" "Should show secret value"
    assert_contains "$print_output" "Total.*1.*secret" "Should show total count"
}

# Test print command with multiple secrets
test_secret_print_multiple_secrets() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # Skip test if OpenSSL not available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Add multiple secrets
    D secret add <<< $'MULTI_SECRET_1\nvalue_one'
    assert_equals "0" "$?" "Should be able to add first secret"
    
    D secret add <<< $'MULTI_SECRET_2\nvalue_two'
    assert_equals "0" "$?" "Should be able to add second secret"
    
    # Print all secrets
    local print_output
    print_output=$(D secret print 2>&1)
    
    # Should succeed and contain both secrets
    assert_equals "0" "$?" "Print command should succeed with multiple secrets"
    assert_contains "$print_output" "MULTI_SECRET_1" "Should show first secret name"
    assert_contains "$print_output" "MULTI_SECRET_2" "Should show second secret name"
    assert_contains "$print_output" "value_one" "Should show first secret value"
    assert_contains "$print_output" "value_two" "Should show second secret value"
    
    # Should show total count
    assert_contains "$print_output" "Total.*2.*secret" "Should show total count of 2"
}

# Test print command shows usage instructions
test_secret_print_shows_usage_instructions() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # Skip test if OpenSSL not available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Add a secret to trigger usage instructions
    D secret add <<< $'USAGE_TEST_SECRET\nusage_test_value' 2>&1
    assert_equals "0" "$?" "Should be able to add a secret for testing"
    
    # Print secrets and check for usage instructions
    local print_output
    print_output=$(D secret print 2>&1)
    
    # Should succeed and show usage instructions
    assert_equals "0" "$?" "Print command should succeed"
    assert_contains "$print_output" "export.*SECRET_NAME\|To export" "Should show export usage instructions"
    assert_contains "$print_output" "secret export" "Should mention secret export command"
}

# # Test print command with decryption failure
# test_secret_print_decryption_failure() {
#     # Check if OpenSSL is available first
#     local openssl_check
#     openssl_check=$(D secret available --quiet 2>&1)
    
#     # Skip test if OpenSSL not available
#     assert_equals "0" "$?" "OpenSSL should be available for this test"
    
#     # Create a test key first to ensure encryption is set up
#     D secret key-set <<< "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890" 2>&1
    
#     # Add a normal secret
#     D secret add <<< $'NORMAL_SECRET\nnormal_value' 2>&1

#     # Then intentionally invalidate the key but keep a secret file by setting a different key
#     D secret key-reset --force 2>&1
#     D secret key-set <<< "different1234567890different1234567890different1234567890different1234" 2>&1
    
#     # Add another secret with the new key
#     D secret add <<< $'NEW_KEY_SECRET\nnew_key_value' 2>&1

#     # Try to print secrets - should show one decryption failure and one success
#     local print_output
#     print_output=$(D secret print 2>&1)
    
#     # Should indicate decryption failure for the first secret
#     assert_equals "0" "$?" "Print command should complete even with decryption failures"
#     assert_contains "$print_output" "FAILED TO DECRYPT\|DECRYPT\|⚠️\|Error" "Should indicate decryption failure"
#     assert_contains "$print_output" "NEW_KEY_SECRET" "Should show the valid secret name"
#     assert_contains "$print_output" "new_key_value" "Should show the valid secret value"
# }

# Test print command output format
test_secret_print_output_format() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    
    # Skip test if OpenSSL not available
    assert_equals "0" "$?" "OpenSSL should be available for this test"
    
    # Add a secret with known formatting
    D secret add <<< $'FORMAT_SECRET\nformat_value' 2>&1 >/dev/null
    assert_equals "0" "$?" "Should be able to add a secret for format testing"
    
    # Print and check format
    local print_output
    print_output=$(D secret print 2>&1)
    
    # Should succeed with proper formatting
    assert_equals "0" "$?" "Print command should succeed"
    
    # Should have readable format with proper spacing/structure
    local line_count=$(echo "$print_output" | wc -l | tr -d ' ')
    assert_not_equals "1" "$line_count" "Should have multiple lines for formatting"
    
    # Should contain empty lines for readability
    echo "$print_output" | grep -q "^$"
    assert_equals "0" "$?" "Should contain empty lines for readability"
}
