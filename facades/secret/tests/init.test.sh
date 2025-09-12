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
    
    # Verify that no secrets directory was created during failed initialization
    if [ -d "$SECRETS_DIR" ]; then
        assert_directory_empty "$SECRETS_DIR" "Failed init should not create or modify secrets"
    fi
}

# Test init command with quiet flag
test_secret_init_quiet_flag() {
    # Test with invalid argument first
    local invalid_output
    invalid_output=$(D secret init TEST_SECRET --invalid-arg 2>&1)
    local invalid_result=$?
    
    assert_not_equals "0" "$invalid_result" "Should fail with invalid argument"
    assert_contains "$invalid_output" "Unknown argument" "Should indicate unknown argument"
    
    # Test with quiet flag (providing input via heredoc)
    local quiet_output
    quiet_output=$(D secret init TEST_SECRET_QUIET --quiet <<< "test_quiet_value" 2>&1)
    local quiet_result=$?
    
    # Verify quiet mode behavior
    assert_equals "0" "$quiet_result" "Init with quiet flag should succeed"
    assert_equals "" "$quiet_output" "Quiet mode should produce no output on success"
    
    # Verify the secret was actually created
    local verify_output
    verify_output=$(D secret export TEST_SECRET_QUIET 2>&1)
    assert_equals "0" "$?" "Secret should exist after quiet initialization"
    assert_equals "test_quiet_value" "$verify_output" "Secret should have the correct value"
}

# Test init command with non-existent secret (should prompt to create)
test_secret_init_nonexistent_secret() {
    # Clear any existing secrets
    rm -rf "$SECRETS_DIR"
    
    # Try to init a non-existent secret with input provided
    local output
    output=$(D secret init INIT_TEST_SECRET <<< "init_test_value" 2>&1)
    local result=$?
    
    # Verify behavior for non-existent secrets
    assert_equals "0" "$result" "Should successfully initialize non-existent secret"
    assert_contains "$output" "Initializing\|created\|initialized" "Should indicate initialization process"
    
    # Verify the secret was actually created with correct value
    local verify_output
    verify_output=$(D secret export INIT_TEST_SECRET 2>&1)
    assert_equals "0" "$?" "Secret should exist after initialization"
    assert_equals "init_test_value" "$verify_output" "Secret should have the value provided during init"
}

# Test init command with existing valid secret
test_secret_init_existing_valid_secret() {
    # Clear any existing secrets
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # First add a secret
    local add_output
    add_output=$(D secret add EXISTING_INIT_SECRET <<< "existing_init_value" 2>&1)
    local add_result=$?
    assert_equals "0" "$add_result" "Should be able to add the secret first"
    
    # Capture the modification time of the secret file
    local secret_file="$SECRETS_DIR/EXISTING_INIT_SECRET"
    local mod_time_before=$(stat -f "%m" "$secret_file" 2>/dev/null)
    
    # Now init the existing secret (should not overwrite)
    local init_output
    init_output=$(D secret init EXISTING_INIT_SECRET <<< "different_value" 2>&1)
    local init_result=$?
    
    # Verify initialization behavior with existing secret
    assert_equals "0" "$init_result" "Init should succeed with existing valid secret"
    assert_contains "$init_output" "already exists\|already initialized\|using existing" "Should indicate secret already exists"
    
    # Verify the original value was preserved
    local verify_output
    verify_output=$(D secret export EXISTING_INIT_SECRET 2>&1)
    assert_equals "0" "$?" "Secret should still exist after init"
    assert_equals "existing_init_value" "$verify_output" "Original secret value should be preserved"
    
    # Verify the file was not modified
    local mod_time_after=$(stat -f "%m" "$secret_file" 2>/dev/null)
    assert_equals "$mod_time_before" "$mod_time_after" "Secret file should not be modified during init of existing secret"
}

# Test init command initializes secrets system
test_secret_init_initializes_system() {
    # Remove secrets directory if it exists
    rm -rf "$SECRETS_DIR"
    
    # Verify secrets directory doesn't exist initially
    assert_not_file_exists "$SECRETS_DIR" "Secrets directory should not exist initially"
    
    # Try to init a secret (this should initialize the system)
    local output
    output=$(D secret init SYSTEM_INIT_SECRET <<< "system_init_value" 2>&1)
    local result=$?
    
    # Verify initialization worked
    assert_equals "0" "$result" "Init should succeed and initialize system"
    assert_contains "$output" "initializing\|initialized\|created" "Should indicate successful initialization"
    
    # Verify secrets directory was created
    assert_file_exists "$SECRETS_DIR" "Should create secrets directory during init"
    assert_directory_not_empty "$SECRETS_DIR" "Secrets directory should contain files after init"
    
    # Verify the secret was created with correct value
    local verify_output
    verify_output=$(D secret export SYSTEM_INIT_SECRET 2>&1)
    assert_equals "0" "$?" "Secret should exist after system initialization"
    assert_equals "system_init_value" "$verify_output" "Secret should have the correct value"
}

# Test init command with invalid secret name
test_secret_init_invalid_secret_name() {
    # Try to init with different invalid secret names and verify each case
    
    # Test empty name
    local empty_output
    empty_output=$(D secret init "" 2>&1)
    local empty_result=$?
    assert_not_equals "0" "$empty_result" "Init should fail with empty secret name"
    assert_contains "$empty_output" "Secret name required\|invalid\|empty" "Should indicate empty name is invalid"
    
    # Test name with spaces
    local spaces_output
    spaces_output=$(D secret init "INVALID SECRET" 2>&1)
    local spaces_result=$?
    assert_not_equals "0" "$spaces_result" "Init should fail with spaces in name"
    assert_contains "$spaces_output" "invalid\|name\|format\|contains spaces" "Should indicate spaces are not allowed"
    
    # Test name with special characters
    local special_output
    special_output=$(D secret init "invalid-secret!" 2>&1)
    local special_result=$?
    assert_not_equals "0" "$special_result" "Init should fail with special characters"
    assert_contains "$special_output" "invalid\|name\|format\|special characters" "Should indicate special characters are not allowed"
    
    # Verify no secrets were created during these failed attempts
    local existing_secrets
    existing_secrets=$(find "$SECRETS_DIR" -type f -name "INVALID*" 2>/dev/null | wc -l | tr -d ' ')
    assert_equals "0" "$existing_secrets" "No secrets should be created with invalid names"
}

# Test init command ensures encryption key exists
test_secret_init_ensures_encryption_key() {
    # Clean up environment first
    rm -rf "$SECRETS_DIR"
    
    # Get the key file path (may depend on implementation)
    local key_file="$SECRETS_DIR/.key"
    
    # Verify no key exists initially
    assert_not_file_exists "$key_file" "No key file should exist initially"
    
    # Init a secret (should create key as part of initialization)
    local output
    output=$(D secret init KEY_INIT_SECRET <<< "key_init_value" 2>&1)
    local result=$?
    
    # Verify init succeeded
    assert_equals "0" "$result" "Init should succeed and create necessary components"
    
    # Verify a key was created
    assert_file_exists "$key_file" "Key file should be created during init"
    
    # Verify key works by checking the exported secret value
    local verify_output
    verify_output=$(D secret export KEY_INIT_SECRET 2>&1)
    assert_equals "0" "$?" "Should be able to export secret with generated key"
    assert_equals "key_init_value" "$verify_output" "Secret should be correctly encrypted/decrypted with generated key"
    
    # Verify key can be displayed
    local key_output
    key_output=$(D secret key-show 2>&1)
    local key_result=$?
    assert_equals "0" "$key_result" "Should be able to display the generated key"
    assert_contains "$key_output" "Current encryption key" "Key output should contain expected text"
}

# Test init command handles missing OpenSSL
test_secret_init_handles_missing_openssl() {
    # Create a mock function to simulate missing OpenSSL
    local original_path="$PATH"
    
    # Create a directory for our mock commands
    local mock_dir="$TEST_CTX/mock_bin"
    mkdir -p "$mock_dir"
    
    # Create a mock openssl that fails
    cat > "$mock_dir/openssl" << 'EOF'
#!/bin/bash
echo "openssl: command not found" >&2
exit 127
EOF
    chmod +x "$mock_dir/openssl"
    
    # Use the mock openssl by putting it first in PATH
    export PATH="$mock_dir:$original_path"
    
    # Try to use init command
    local output
    output=$(D secret init MOCK_TEST_SECRET <<< "test_value" 2>&1)
    local result=$?
    
    # Restore original PATH
    export PATH="$original_path"
    
    # Verify behavior with missing OpenSSL
    assert_not_equals "0" "$result" "Init should fail without OpenSSL"
    assert_contains "$output" "OpenSSL\|required\|available\|not found" "Should indicate OpenSSL requirement"
    
    # Clean up
    rm -rf "$mock_dir"
}

# Test init command output messages
test_secret_init_output_messages() {
    # Clear previous test artifacts
    rm -rf "$SECRETS_DIR"
    
    # Test init command output format
    local output
    output=$(D secret init OUTPUT_TEST_SECRET <<< "output_test_value" 2>&1)
    local result=$?
    
    # Verify init succeeded
    assert_equals "0" "$result" "Init should succeed"
    
    # Verify expected output messages
    assert_contains "$output" "Initializing secret\|Initialize\|init" "Should indicate initialization process"
    assert_contains "$output" "successfully\|SUCCESS\|initialized" "Should indicate successful initialization"
    
    # Verify the actual secret value
    local verify_output
    verify_output=$(D secret export OUTPUT_TEST_SECRET 2>&1)
    assert_equals "0" "$?" "Secret should exist after initialization"
    assert_equals "output_test_value" "$verify_output" "Secret should have the correct value"
}

# Test init command with quiet flag and existing secret
test_secret_init_quiet_existing_secret() {
    # Clear previous test artifacts
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # First add a secret
    local add_output
    add_output=$(D secret add QUIET_EXISTING_SECRET <<< "quiet_existing_value" 2>&1)
    local add_result=$?
    assert_equals "0" "$add_result" "Should be able to add the secret first"
    
    # Capture the modification time of the secret file
    local secret_file="$SECRETS_DIR/QUIET_EXISTING_SECRET"
    local mod_time_before=$(stat -f "%m" "$secret_file" 2>/dev/null)
    
    # Now init the existing secret with quiet flag (attempt to provide different value)
    local init_output
    init_output=$(D secret init QUIET_EXISTING_SECRET --quiet <<< "new_value_shouldnt_be_used" 2>&1)
    local init_result=$?
    
    # Verify quiet init behavior with existing secret
    assert_equals "0" "$init_result" "Init with quiet flag should succeed for existing secret"
    assert_equals "" "$init_output" "Quiet mode should produce no output on success"
    
    # Verify the original value was preserved
    local verify_output
    verify_output=$(D secret export QUIET_EXISTING_SECRET 2>&1)
    assert_equals "0" "$?" "Secret should still exist after quiet init"
    assert_equals "quiet_existing_value" "$verify_output" "Original secret value should be preserved, not overwritten"
    
    # Verify the file was not modified
    local mod_time_after=$(stat -f "%m" "$secret_file" 2>/dev/null)
    assert_equals "$mod_time_before" "$mod_time_after" "Secret file should not be modified during quiet init of existing secret"
}
