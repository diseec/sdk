#!/bin/bash

# Test for the 'secret export' command

# Setup function - runs before each test
setup_test() {
    # Set up secrets directory in the test workspace
    export SECRETS_DIR="$TEST_CTX/secrets"
    mkdir -p "$SECRETS_DIR" 2>/dev/null
    
    # Generate and configure an encryption key for tests
    local test_key="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    D secret key-set <<< "$test_key" >/dev/null 2>&1
}

# Test export command requires secret name
test_secret_export_requires_name() {
    local output

    output=$(D secret export)
    
    # Verify command fails without secret name
    assert_not_equals "0" "$?" "Export should fail without secret name"
    assert_contains "$output" "Secret name required\|Usage" "Should indicate secret name is required"
    
    # Verify help information is provided
    assert_contains "$output" "export" "Should mention the command in usage info"
    assert_contains "$output" "D secret export" "Should show command syntax"
}

# Test export command with non-existent secret
test_secret_export_nonexistent_secret() {
    # Attempt to export the non-existent secret
    local output
    output=$(D secret export NONEXISTENT_SECRET)
    
    # Verify command fails with appropriate error message
    assert_not_equals "0" "$?" "Export should fail with non-existent secret"
    assert_contains "$output" "not found\|does not exist" "Should indicate secret not found"
    assert_contains "$output" "NONEXISTENT_SECRET" "Should mention the specific secret name"
}

# Test export command with existing secret
test_secret_export_existing_secret_only() {
    # Create and initialize a test secret
    local test_secret="EXPORT_TEST_SECRET"
    local test_value="export_test_value_456"
    D secret add
    # Use the add command to create the secret
    local add_output
    add_output=$(D secret add <<EOF
$test_secret
$test_value
EOF
)
    
    # Verify secret was added successfully
    assert_equals "0" "$?" "Should be able to initialize the secret for export testing"
    assert_contains "$add_output" "added successfully" "Secret should be added successfully"
    
    # Now try to export it
    local export_output
    export_output=$(D secret export "$test_secret")
    
    # Verify export succeeded and returned the correct value
    assert_equals "0" "$?" "Export should succeed with existing valid secret"
    assert_equals "$test_value" "$export_output" "Should export the exact secret value"
    
    # Verify no additional output/formatting was added
    local line_count=$(echo "$export_output" | wc -l | tr -d ' ')
    assert_equals "1" "$line_count" "Export should return a single line with just the value"
}

# Test export command without encryption key configured
test_secret_export_no_key_configured_only() {
    # First create a test secret with the current key
    local mock_secret="MOCK_SECRET_NO_KEY"
    local test_value="test_value_for_no_key"
    
    # Directly create an encrypted secret file
    local key=$(cli_ctx config get "secrets.key")
    local encrypted_value=$(echo "$test_value" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64)
    echo "$encrypted_value" > "$SECRETS_DIR/$mock_secret"
    
    # Now reset the key by removing the config entry
    cli_ctx config remove "secrets.key" >/dev/null 2>&1
    
    # Try to export without key
    local output
    D secret export "$mock_secret"
    x $output <<EOF
    y
EOF
    output=$()
    
    # Verify failure due to missing key
    assert_not_equals "0" "$?" "Export should fail without encryption key"
    assert_contains "$output" "key\|configured\|encryption\|decrypt" "Should indicate key configuration issue"
    
    # Verify error message mentions the specific secret
    assert_contains "$output" "$mock_secret" "Error should mention the specific secret"
}

# Test export command output format
test_secret_export_output_format() {
    # Create and initialize a test secret with a multiline value
    local test_secret="FORMAT_TEST_SECRET"
    local test_value="line1
line2
line3"
    
    # Directly create an encrypted secret file
    local key=$(cli_ctx config get "secrets.key")
    local encrypted_value=$(printf '%s' "$test_value" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64)
    echo "$encrypted_value" > "$SECRETS_DIR/$test_secret"
    
    # Verify file creation succeeded
    assert_equals "0" "$?" "Should be able to initialize the secret for format testing"
    
    # Export and check output format
    local export_output
    export_output=$(D secret export "$test_secret")
    
    # Verify export succeeded
    assert_equals "0" "$?" "Export should succeed with properly initialized secret"
    
    # Verify output matches the exact input value
    assert_equals "$test_value" "$export_output" "Export should return exactly the secret value"
    
    # Verify line count matches the input value
    local expected_lines=$(echo "$test_value" | wc -l | tr -d ' ')
    local actual_lines=$(echo "$export_output" | wc -l | tr -d ' ')
    assert_equals "$expected_lines" "$actual_lines" "Export should preserve line count"
    
    # Verify no additional text or formatting was added
    assert_not_contains "$export_output" "Secret:" "Export should not include labels or extra text"
    assert_not_contains "$export_output" "Value:" "Export should not include labels or extra text"
}

# Test export command with special characters in secret value
test_secret_export_special_characters() {
    # Test value with special characters
    local test_secret="SPECIAL_CHARS_SECRET"
    local special_value="password!@#$%^&*()_+-={}[]|\\:;\"'<>,.?/"
    
    # Directly create an encrypted secret file
    local key=$(cli_ctx config get "secrets.key")
    local encrypted_value=$(printf '%s' "$special_value" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64)
    echo "$encrypted_value" > "$SECRETS_DIR/$test_secret"
    
    # Verify file creation succeeded
    assert_equals "0" "$?" "Should be able to initialize the secret with special characters"
    
    # Export and verify special characters are preserved
    local export_output
    export_output=$(D secret export "$test_secret")
    
    # Verify export succeeded
    assert_equals "0" "$?" "Export should succeed with special characters"
    
    # Verify special characters are preserved
    assert_equals "$special_value" "$export_output" "Export should preserve all special characters"
    
    # Verify length matches expected
    local expected_length=${#special_value}
    local actual_length=${#export_output}
    assert_equals "$expected_length" "$actual_length" "Export should preserve exact length of value with special characters"
}

# Test export command with quiet flag
test_secret_export_with_quiet_flag() {
    # Create and initialize a test secret
    local test_secret="QUIET_EXPORT_SECRET"
    local test_value="quiet_test_value"
    
    # Directly create an encrypted secret file
    local key=$(cli_ctx config get "secrets.key")
    local encrypted_value=$(printf '%s' "$test_value" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64)
    echo "$encrypted_value" > "$SECRETS_DIR/$test_secret"
    
    # Verify file creation succeeded
    assert_equals "0" "$?" "Should be able to initialize the secret for quiet flag testing"
    
    # Export with quiet flag
    local export_output
    export_output=$(D secret export "$test_secret" --quiet)
    
    # Verify export succeeded
    assert_equals "0" "$?" "Export with quiet flag should succeed with valid secret"
    
    # Verify output is the exact secret value (should be the same as without quiet flag)
    assert_equals "$test_value" "$export_output" "Export with quiet flag should return exact secret value"
    
    # Compare with non-quiet output to ensure they're the same
    local regular_output
    regular_output=$(D secret export "$test_secret")
    assert_equals "$regular_output" "$export_output" "Quiet export should produce same output as regular export"
}
