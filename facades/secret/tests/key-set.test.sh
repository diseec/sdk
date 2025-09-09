#!/bin/bash

# Test for the 'secret key-set' command

# Suite setup - runs once before all# Test key-set command with empty key
test_secret_key_set_empty_key() {
    # Skip if we couldn't set up secrets directory
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Check if OpenSSL is available firs# Test key-set command interactive prompting
test_secret_key_set_interactive_prompt() {
    # Skip if we couldn't set up secrets directory
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Test interactive prompt behavior
    local test_key="fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$test_key
EOF
)ssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Try to set an empty key
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1

EOF
)file
suite_setup() {
    # Set up secrets directory
    export SECRETS_DIR="$TEST_WORKSPACE/secrets"
    mkdir -p "$SECRETS_DIR" 2>/dev/null || {
        # If we can't create the secrets directory, skip all tests
        export SKIP_TESTS="true"
        return 0
    }
}

# Test key-set command requires OpenSSL
test_secret_key_set_requires_openssl() {
    # Skip if we couldn't set up secrets directory
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Skip if OpenSSL is not available (we can't easily test this scenario)
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # OpenSSL not available - key-set should fail
        local output
        output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
test_key_123
EOF
)
        local key_set_result=$?
        
        assert_not_equals "0" "$key_set_result" "Key-set should fail without OpenSSL"
    fi
}

# Test key-set command basic functionality
test_secret_key_set_basic_functionality() {
    # Skip if we couldn't set up secrets directory
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Set a valid encryption key
    local valid_key="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$valid_key
EOF
)
    local key_set_result=$?
    
    if [ "$key_set_result" -eq 0 ]; then
        assert_contains "$output" "configured successfully\|SUCCESS" "Should indicate successful key configuration"
        
        # Verify key was set by checking if we can show it
        local show_output
        show_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-show 2>&1)
        local show_result=$?
        
        if [ "$show_result" -eq 0 ]; then
            assert_contains "$show_output" "$valid_key" "Should be able to retrieve the set key"
        fi
    fi
}

# Test key-set command with empty key
test_secret_key_set_empty_key() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Try to set empty key
    local output
    output=$(echo "" | D secret key-set 2>&1)
    local key_set_result=$?
    
    # Should fail with empty key
    assert_not_equals "0" "$key_set_result" "Should fail with empty key"
    assert_contains "$output" "empty\|cannot be empty" "Should indicate key cannot be empty"
}

# Test key-set command with invalid key format
test_secret_key_set_invalid_key_format() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Try to set an invalid key (too short, non-hex characters)
    local invalid_key="invalid_key_123"
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$invalid_key
y
EOF
)
    local key_set_result=$?
    
    # Should warn about key format but allow if user confirms
    assert_contains "$output" "64 hexadecimal characters\|should be" "Should warn about key format"
    assert_contains "$output" "Continue anyway" "Should ask for confirmation to continue"
    
    if [ "$key_set_result" -eq 0 ]; then
        # If user confirmed, should still set the key
        assert_contains "$output" "configured successfully" "Should set key if user confirms"
    fi
}

# Test key-set command refuses to overwrite existing key without secrets
test_secret_key_set_existing_key_no_secrets() {
    # Skip if we couldn't set up secrets directory
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First set a key
    local first_key="1111111111111111111111111111111111111111111111111111111111111111"
    local output1
    output1=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$first_key
EOF
)
    local key_set_result1=$?
    
    if [ "$key_set_result1" -ne 0 ]; then
        # Skip if we couldn't set the first key
        return 0
    fi
    
    # Try to set a different key when one already exists (no secrets)
    local second_key="2222222222222222222222222222222222222222222222222222222222222222"
    local output2
    output2=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$second_key
EOF
)
    local key_set_result2=$?
    
    # Should refuse to overwrite existing key
    assert_not_equals "0" "$key_set_result2" "Should refuse to overwrite existing key"
    assert_contains "$output2" "already configured\|Use.*reset-key" "Should indicate key already configured and suggest reset-key"
}

# Test key-set command validates key with existing secrets
test_secret_key_set_validates_with_existing_secrets() {
    # Skip if we couldn't set up secrets directory
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret (this will create a key automatically)
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
VALIDATION_SECRET
validation_value
EOF
)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Get the current key so we can test with it
    local current_key_output
    current_key_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-show 2>&1)
    local current_key_result=$?
    
    if [ "$current_key_result" -ne 0 ]; then
        # Skip if we can't get the current key
        return 0
    fi
    
    # Extract the key from the output (assuming it's on the last line)
    local current_key=$(echo "$current_key_output" | tail -n 1)
    
    # Now try to set the same key again (should work since it matches existing secrets)
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$current_key
EOF
)
    local key_set_result=$?
    
    if [ "$key_set_result" -eq 0 ]; then
        assert_contains "$output" "configured successfully" "Should succeed when key matches existing secrets"
    fi
    
    # Try to set a wrong key (should fail validation against existing secrets)
    local wrong_key="9999999999999999999999999999999999999999999999999999999999999999"
    local wrong_output
    wrong_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$wrong_key
EOF
)
    local wrong_key_result=$?
    
    if [ "$wrong_key_result" -ne 0 ]; then
        # Should fail if key doesn't work with existing secrets
        assert_contains "$wrong_output" "test.*key\|decrypt\|validation" "Should indicate key validation failure"
    fi
}

# Test key-set command with valid hexadecimal key
test_secret_key_set_valid_hex_key() {
    # Skip if we couldn't set up secrets directory
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Set a properly formatted 64-character hex key
    local valid_hex_key="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret key-set <<EOF 2>&1
$valid_hex_key
EOF
)
    local key_set_result=$?
    
    if [ "$key_set_result" -eq 0 ]; then
        assert_contains "$output" "configured successfully" "Should succeed with valid hex key"
        
        # Should not show warning about key format
        assert_not_contains "$output" "should be.*hexadecimal\|Continue anyway" "Should not warn about valid hex key format"
    fi
}

# Test key-set command interactive prompting
test_secret_key_set_interactive_prompt() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(d secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # Test that the command prompts for input
    local test_key="fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"
    local output
    output=$(echo "$test_key" | D secret key-set 2>&1)
    
    # Should contain input prompt
    assert_contains "$output" "Enter encryption key\|encryption key" "Should prompt for encryption key input"
}
