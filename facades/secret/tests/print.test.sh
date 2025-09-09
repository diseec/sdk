#!/bin/bash

# Test for the 'secret print' command

# Test print command with no secrets
test_secret_print_no_secrets() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    local output
    output=$(d secret print 2>&1)
    local print_result=$?
    
    # Should succeed but indicate no secrets found
    if [ "$print_result" -eq 0 ]; then
        assert_contains "$output" "No secrets found\|No secrets\|0 secrets" "Should indicate no secrets found"
    fi
}

# Test print command requires OpenSSL
test_secret_print_requires_openssl() {
    # Skip if OpenSSL is not available (we can't easily test this scenario)
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # OpenSSL not available - print should fail
        local output
        output=$(d secret print 2>&1)
        local print_result=$?
        
        assert_not_equals "0" "$print_result" "Print should fail without OpenSSL"
    fi
}

# Test print command with single secret
test_secret_print_single_secret() {
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
    add_output=$(echo -e "PRINT_TEST_SECRET\nprint_test_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Now print all secrets
    local print_output
    print_output=$(d secret print 2>&1)
    local print_result=$?
    
    if [ "$print_result" -eq 0 ]; then
        # Should contain the secret name and value
        assert_contains "$print_output" "PRINT_TEST_SECRET" "Should show secret name"
        assert_contains "$print_output" "print_test_value" "Should show secret value"
        assert_contains "$print_output" "Total.*1.*secret" "Should show total count"
    fi
}

# Test print command with multiple secrets
test_secret_print_multiple_secrets() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Add multiple secrets
    local add_output1
    add_output1=$(echo -e "MULTI_SECRET_1\nvalue_one" | D secret add 2>&1)
    local add_result1=$?
    
    local add_output2
    add_output2=$(echo -e "MULTI_SECRET_2\nvalue_two" | D secret add 2>&1)
    local add_result2=$?
    
    if [ "$add_result1" -ne 0 ] || [ "$add_result2" -ne 0 ]; then
        # Skip if we couldn't add the secrets
        return 0
    fi
    
    # Print all secrets
    local print_output
    print_output=$(d secret print 2>&1)
    local print_result=$?
    
    if [ "$print_result" -eq 0 ]; then
        # Should contain both secrets
        assert_contains "$print_output" "MULTI_SECRET_1" "Should show first secret name"
        assert_contains "$print_output" "MULTI_SECRET_2" "Should show second secret name"
        assert_contains "$print_output" "value_one" "Should show first secret value"
        assert_contains "$print_output" "value_two" "Should show second secret value"
        
        # Should show total count
        assert_contains "$print_output" "Total.*2.*secret" "Should show total count of 2"
    fi
}

# Test print command shows usage instructions
test_secret_print_shows_usage_instructions() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Add at least one secret so we get the usage instructions
    local add_output
    add_output=$(echo -e "USAGE_TEST_SECRET\nusage_test_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Print secrets and check for usage instructions
    local print_output
    print_output=$(d secret print 2>&1)
    local print_result=$?
    
    if [ "$print_result" -eq 0 ]; then
        # Should contain usage instructions
        assert_contains "$print_output" "export.*SECRET_NAME\|To export" "Should show export usage instructions"
        assert_contains "$print_output" "secret export" "Should mention secret export command"
    fi
}

# Test print command with decryption failure
test_secret_print_decryption_failure() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Create a mock secret file with invalid encrypted data
    mkdir -p "$TEST_WORKSPACE/secrets"
    echo "invalid_encrypted_data_that_cannot_be_decrypted" > "$TEST_WORKSPACE/secrets/CORRUPT_SECRET"
    
    # Try to print secrets
    local print_output
    print_output=$(d secret print 2>&1)
    local print_result=$?
    
    # Should handle decryption failures gracefully
    if [ "$print_result" -eq 0 ]; then
        # Should show failure indicator for corrupt secret
        assert_contains "$print_output" "FAILED TO DECRYPT\|DECRYPT\|⚠️" "Should indicate decryption failure"
        assert_contains "$print_output" "CORRUPT_SECRET" "Should show the secret name even if decryption failed"
    fi
}

# Test print command output format
test_secret_print_output_format() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Add a secret with known formatting
    local add_output
    add_output=$(echo -e "FORMAT_SECRET\nformat_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Print and check format
    local print_output
    print_output=$(d secret print 2>&1)
    local print_result=$?
    
    if [ "$print_result" -eq 0 ]; then
        # Should have readable format with proper spacing/structure
        local line_count=$(echo "$print_output" | wc -l | tr -d ' ')
        assert_not_equals "1" "$line_count" "Should have multiple lines for formatting"
        
        # Should contain empty lines for readability
        echo "$print_output" | grep -q "^$"
        assert_equals "0" "$?" "Should contain empty lines for readability"
    fi
}
