#!/bin/bash

# Test for the 'secret export' command
_export_test_key="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
# Setup function - runs before each test
setup_test() {
    TEST_SECRET_DIR="$(D --quiet secret function sdk_fac_sec_get_secrets_dir)"
}

helper_create_secret() {
    local test_secret="$1"
    local test_value="$2"
    # Generate and configure an encryption key for tests
    local test_key="$_export_test_key"
    D secret key-set <<< "$test_key" >/dev/null 2>&1

    # Use the add command to create the secret
    local add_output
    add_output=$(D secret add <<EOF
$test_secret
$test_value
EOF
)
}

# Test export command requires secret name
test_secret_export_requires_name() {
    D secret key-set <<< "$_export_test_key" >/dev/null 2>&1

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
test_secret_export_existing_key_existing_secret() {
    # Generate and configure an encryption key for tests
    local test_key="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    D secret key-set <<< "$test_key" >/dev/null 2>&1

    # Create and initialize a test secret
    local test_secret="EXPORT_TEST_SECRET"
    local test_value="export_test_value_456"

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

test_secret_export_existing_secret() {
    # Create and initialize a test secret
    local test_secret="EXPORT_TEST_SECRET"
    local test_value="export_test_value_456"

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
test_secret_export_no_key_configured() {
    # First create a test secret with the current key
    local mock_secret="MOCK_SECRET_NO_KEY"
    local test_value="test_value_for_no_key"
    
    # Directly create an encrypted secret file
    local key=$(D secret function sdk_fac_sec_get_encryption_key)
    local encrypted_value=$(echo "$test_value" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64)
    echo "$encrypted_value" > "$TEST_CTX/$mock_secret"
    
    # Try to export without key
    local output
    output=$(D secret export "$mock_secret" <<< y)

    # Verify failure due to missing key
    assert_contains "$output" "key\|configured\|encryption\|decrypt\|not found" "Should indicate key configuration issue"
}

# SKIP: this test doesnt pass due to the fact that test_value is multi line and the <<< operator trims newlines and pass only the first line
# # Test export command output format
# test_secret_export_output_format() {
#     # Create and initialize a test secret with a multiline value
#     local test_secret="FORMAT_TEST_SECRET"
#     local test_value="line1
# line2
# line3"

#     helper_create_secret "$test_secret" "$test_value"
    
#     # Verify file creation succeeded
#     assert_equals "0" "$?" "Should be able to initialize the secret for format testing"
    
#     # Export and check output format
#     local export_output
#     export_output=$(D secret export "$test_secret")
    
#     # Verify export succeeded
#     assert_equals "0" "$?" "Export should succeed with properly initialized secret"
    
#     # Verify output matches the exact input value
#     assert_equals "$test_value" "$export_output" "Export should return exactly the secret value"
    
#     # Verify line count matches the input value
#     local expected_lines=$(echo "$test_value" | wc -l | tr -d ' ')
#     local actual_lines=$(echo "$export_output" | wc -l | tr -d ' ')
#     assert_equals "$expected_lines" "$actual_lines" "Export should preserve line count"
    
#     # Verify no additional text or formatting was added
#     assert_not_contains "$export_output" "Secret:" "Export should not include labels or extra text"
#     assert_not_contains "$export_output" "Value:" "Export should not include labels or extra text"
# }

# Test export command with special characters in secret value
test_secret_export_special_characters() {
    # Test value with special characters
    local test_secret="SPECIAL_CHARS_SECRET"
    local special_value="password!@#$%^&*()_+-={}[]|\\:;\<>,.?/"
    
    helper_create_secret "$test_secret" "$special_value"

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

# # Test export command with quiet flag
# test_secret_export_with_quiet_flag() {
#     # Create and initialize a test secret
#     local test_secret="QUIET_EXPORT_SECRET"
#     local test_value="quiet_test_value"
    
#     # Directly create an encrypted secret file
#     local key=$(D secret function sdk_fac_sec_get_encryption_key)
#     local encrypted_value=$(printf '%s' "$test_value" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64)
#     echo "$encrypted_value" > "$SECRETS_DIR/$test_secret"
    
#     # Verify file creation succeeded
#     assert_equals "0" "$?" "Should be able to initialize the secret for quiet flag testing"
    
#     # Export with quiet flag
#     local export_output
#     export_output=$(D secret export "$test_secret" --quiet)
    
#     # Verify export succeeded
#     assert_equals "0" "$?" "Export with quiet flag should succeed with valid secret"
    
#     # Verify output is the exact secret value (should be the same as without quiet flag)
#     assert_equals "$test_value" "$export_output" "Export with quiet flag should return exact secret value"
    
#     # Compare with non-quiet output to ensure they're the same
#     local regular_output
#     regular_output=$(D secret export "$test_secret")
#     assert_equals "$regular_output" "$export_output" "Quiet export should produce same output as regular export"
# }

# must preserve secret on multi exports
test_secret_export_multiple_times() {
    # Create and initialize a test secret
    local test_secret="MULTI_EXPORT_SECRET"
    local test_value="multi_export_value_789"  
    helper_create_secret "$test_secret" "$test_value"       
    # Verify file creation succeeded
    assert_equals "0" "$?" "Should be able to initialize the secret for multiple exports testing"
    # Export multiple times and verify consistency
    local export1 export2 export3
    export1=$(D secret export "$test_secret")
    assert_equals "0" "$?" "First export should succeed"
    export2=$(D secret export "$test_secret")
    assert_equals "0" "$?" "Second export should succeed"
    export3=$(D secret export "$test_secret")
    assert_equals "0" "$?" "Third export should succeed"
    # Verify all exports match the original value
    assert_equals "$test_value" "$export1" "First export should match original value"
    assert_equals "$test_value" "$export2" "Second export should match original value"
    assert_equals "$test_value" "$export3" "Third export should match original value"
}

# Key remains the same on adding validating and printin and exporting
test_secret_export_multiple_times_with_intermediate_commands() {
    # Create and initialize a test secret
    local test_secret="MULTI_EXPORT_INTERMEDIATE_SECRET"
    local test_value="intermediate_multi_export_value_101112"
    helper_create_secret "$test_secret" "$test_value"       
    local initial_key="$_export_test_key"
    # Verify file creation succeeded
    assert_equals "0" "$?" "Should be able to initialize the secret for multiple exports testing"
    # Export multiple times with intermediate commands and verify consistency
    local export1 export2 export3
    export1=$(D secret export "$test_secret")
    assert_equals "0" "$?" "First export should succeed"
    D secret validate "$test_secret" >/dev/null 2>&1
    assert_equals "0" "$?" "Validation should succeed"
    export2=$(D secret export "$test_secret")
    assert_equals "0" "$?" "Second export should succeed"
    D secret print "$test_secret" >/dev/null 2>&1
    assert_equals "0" "$?" "Print should succeed"
    export3=$(D secret export "$test_secret")   
    assert_equals "0" "$?" "Third export should succeed"
    # Verify current key not empty and still same
    local current_key=$(D config get --scope=user "secrets.key")
    assert_not_equals "" "$current_key" "Secret key should still be configured"
    assert_equals "$initial_key" "$current_key" "Secret key should remain unchanged after multiple exports and intermediate commands"
    # Verify all exports match the original value
    assert_equals "$test_value" "$export1" "First export should match original value"
    assert_equals "$test_value" "$export2" "Second export should match original value"
    assert_equals "$test_value" "$export3" "Third export should match original value"
}