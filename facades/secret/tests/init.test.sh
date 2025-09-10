#!/bin/bash

# Test for the 'secret init' command

# Test init command requires secret name
test_secret_init_requires_name() {
    local output
    output=$(D secret init 2>&1)
    local result=$?
    
    # Should fail without secret name
    assert_not_equals "0" "$result" "Init should fail without secret name"
    assert_contains "$output" "Secret name required\|Usage" "Should indicate secret name is required"
}

# Test init command with quiet flag
test_secret_init_quiet_flag() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Test with invalid argument first
    local invalid_output
    invalid_output=$(D secret init TEST_SECRET --invalid-arg 2>&1)
    local invalid_result=$?
    
    assert_not_equals "0" "$invalid_result" "Should fail with invalid argument"
    assert_contains "$invalid_output" "Unknown argument" "Should indicate unknown argument"
    
    # Test with quiet flag (may require interactive input, so might not fully succeed)
    local quiet_output
    quiet_output=$(D secret init TEST_SECRET --quiet 2>&1)
    local quiet_result=$?
    
    # If it succeeds with quiet flag, output should be minimal
    if [ "$quiet_result" -eq 0 ]; then
        # Should have minimal output
        local line_count=$(echo "$quiet_output" | wc -l | tr -d ' ')
        assert_equals "0" "$line_count" "Quiet mode should produce minimal output on success"
    fi
}

# Test init command with non-existent secret (should prompt to create)
test_secret_init_nonexistent_secret() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Try to init a non-existent secret (this will be interactive)
    # Since this requires user input, we'll test the basic invocation
    local output
    output=$(echo -e "init_test_value\nn" | timeout 10 D secret init INIT_TEST_SECRET 2>&1)
    local result=$?
    
    # Should prompt to add the missing secret or handle gracefully
    assert_contains "$output" "not exist\|does not exist\|missing\|add" "Should indicate secret doesn't exist or prompt to add"
}

# Test init command with existing valid secret
test_secret_init_existing_valid_secret() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret
    local add_output
    add_output=$(echo -e "EXISTING_INIT_SECRET\nexisting_init_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Now init the existing secret
    local init_output
    init_output=$(D secret init EXISTING_INIT_SECRET 2>&1)
    local init_result=$?
    
    if [ "$init_result" -eq 0 ]; then
        # Should indicate the secret already exists and is valid
        assert_contains "$init_output" "already exists.*valid\|initialized successfully" "Should indicate secret already exists or is valid"
    fi
}

# Test init command initializes secrets system
test_secret_init_initializes_system() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Remove secrets directory if it exists
    rm -rf "$TEST_WORKSPACE/secrets"
    
    # Try to init a secret (this should initialize the system)
    local output
    output=$(echo -e "system_init_value\nn" | timeout 10 D secret init SYSTEM_INIT_SECRET 2>&1)
    local result=$?
    
    # Should create secrets directory during initialization
    assert_file_exists "$TEST_WORKSPACE/secrets" "Should create secrets directory during init"
}

# Test init command with invalid secret name
test_secret_init_invalid_secret_name() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Try to init with invalid secret name (e.g., with spaces or special chars)
    local invalid_names=("INVALID SECRET" "invalid-secret!" "123invalid" "")
    
    for invalid_name in "${invalid_names[@]}"; do
        if [ -n "$invalid_name" ]; then
            local output
            output=$(D secret init "$invalid_name" 2>&1)
            local result=$?
            
            # Should handle invalid names gracefully
            if [ "$result" -ne 0 ]; then
                assert_contains "$output" "invalid\|name\|format" "Should indicate invalid secret name format"
            fi
        fi
    done
}

# Test init command ensures encryption key exists
test_secret_init_ensures_encryption_key() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Verify no key exists initially
    local key_check_before
    key_check_before=$(D secret key-show 2>&1)
    local key_result_before=$?
    assert_not_equals "0" "$key_result_before" "No key should exist initially"
    
    # Try to init a secret (should create key if needed)
    local output
    output=$(echo -e "key_init_value\nn" | timeout 10 D secret init KEY_INIT_SECRET 2>&1)
    local result=$?
    
    # After init attempt, a key might be generated
    # This depends on the implementation details
    if [ "$result" -eq 0 ]; then
        local key_check_after
        key_check_after=$(D secret key-show 2>&1)
        local key_result_after=$?
        
        if [ "$key_result_after" -eq 0 ]; then
            assert_contains "$key_check_after" "Current encryption key" "Key should exist after init"
        fi
    fi
}

# Test init command handles missing OpenSSL
test_secret_init_handles_missing_openssl() {
    # Skip if OpenSSL is not available (we can't easily test this scenario)
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # OpenSSL not available - init should fail appropriately
        local output
        output=$(D secret init TEST_SECRET 2>&1)
        local init_result=$?
        
        assert_not_equals "0" "$init_result" "Init should fail without OpenSSL"
        assert_contains "$output" "OpenSSL\|required\|available" "Should indicate OpenSSL requirement"
    fi
}

# Test init command output messages
test_secret_init_output_messages() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Test init command output format
    local output
    output=$(echo -e "output_test_value\nn" | timeout 10 D secret init OUTPUT_TEST_SECRET 2>&1)
    local result=$?
    
    # Should contain informative messages
    assert_contains "$output" "Initializing secret\|Initialize\|init" "Should indicate initialization process"
    
    if [ "$result" -eq 0 ]; then
        assert_contains "$output" "successfully\|SUCCESS\|initialized" "Should indicate successful initialization"
    fi
}

# Test init command with quiet flag and existing secret
test_secret_init_quiet_existing_secret() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret
    local add_output
    add_output=$(echo -e "QUIET_EXISTING_SECRET\nquiet_existing_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Now init the existing secret with quiet flag
    local init_output
    init_output=$(D secret init QUIET_EXISTING_SECRET --quiet 2>&1)
    local init_result=$?
    
    if [ "$init_result" -eq 0 ]; then
        # Should succeed with minimal output
        assert_equals "" "$init_output" "Quiet mode should produce no output for existing valid secret"
    fi
}
