#!/bin/bash

# Test for the 'secret clear' command

# Setup function - runs before each test
setup_test() {
    # Set up secrets directory in the test workspace
    export SECRETS_DIR="$TEST_CTX/secrets"
    mkdir -p "$SECRETS_DIR" 2>/dev/null
}

# Test clear command with no secrets
test_secret_clear_no_secrets() {
    # Run clear command
    local output
    output=$(D secret clear <<< "DELETE")
    local result=$?

    # Verify command succeeds with appropriate message
    assert_equals "0" "$result" "Clear command should succeed even with no secrets"
    assert_contains "$output" "No secrets found\|No secrets to clear\|Nothing to clear" "Should indicate no secrets to clear"
}

# Test clear command with existing secrets - confirm deletion
test_secret_clear_existing_secrets_confirm() {
    # Add two test secrets
    echo "clear_value_1" > "$SECRETS_DIR/CLEAR_SECRET_1"
    echo "clear_value_2" > "$SECRETS_DIR/CLEAR_SECRET_2"
    
    # Verify secrets exist before clearing
    assert_file_exists "$SECRETS_DIR/CLEAR_SECRET_1" "First secret file should exist before clearing"
    assert_file_exists "$SECRETS_DIR/CLEAR_SECRET_2" "Second secret file should exist before clearing"
    
    # Clear all secrets with confirmation
    local clear_output
    clear_output=$(D secret clear <<< "DELETE")
    local clear_result=$?
    
    # Verify clear command succeeded
    assert_equals "0" "$clear_result" "Clear command should succeed with confirmation"
    assert_contains "$clear_output" "cleared\|deleted\|removed" "Should indicate successful clearing"
    
    # Verify secrets directory is empty after clearing
    assert_dir_exists "$SECRETS_DIR" "Secrets directory should still exist after clearing"
    # Check that directory is empty by counting files
    local file_count
    file_count=$(find "$SECRETS_DIR" -type f | wc -l | tr -d ' ')
    assert_equals "0" "$file_count" "Secrets directory should be empty after clearing"
    
    # Verify specific secret files no longer exist
    assert_file_not_exists "$SECRETS_DIR/CLEAR_SECRET_1" "First secret file should be deleted"
    assert_file_not_exists "$SECRETS_DIR/CLEAR_SECRET_2" "Second secret file should be deleted"
}

# Test clear command with existing secrets - cancel deletion
test_secret_clear_existing_secrets_cancel() {
    # Add a test secret
    echo "cancel_clear_value" > "$SECRETS_DIR/CANCEL_CLEAR_SECRET"
    
    # Verify secret exists before attempted clearing
    assert_file_exists "$SECRETS_DIR/CANCEL_CLEAR_SECRET" "Secret file should exist before clear attempt"
    
    # Try to clear but cancel (provide anything other than 'DELETE')
    local clear_output
    clear_output=$(D secret clear <<< "CANCEL")
    local clear_result=$?
    
    # Verify secret still exists after cancelled operation
    assert_file_exists "$SECRETS_DIR/CANCEL_CLEAR_SECRET" "Secret file should still exist after cancelled clear"
    
    # Verify secret content is unchanged
    local secret_content
    secret_content=$(cat "$SECRETS_DIR/CANCEL_CLEAR_SECRET")
    assert_equals "cancel_clear_value" "$secret_content" "Secret content should be unchanged after cancelled clear"
}

# Test clear command confirmation prompt
test_secret_clear_confirmation_prompt() {
    # Add a test secret
    echo "prompt_clear_value" > "$SECRETS_DIR/PROMPT_CLEAR_SECRET"
    
    # Capture output to check the confirmation prompt
    local clear_output
    clear_output=$(D secret clear <<< "CANCEL")
    
    # Verify appropriate warnings and confirmation request
    assert_contains "$clear_output" "WARNING\|warning\|caution" "Should show warning message"
    assert_contains "$clear_output" "permanently delete\|will be deleted\|cannot be undone" "Should warn about permanent deletion"
    assert_contains "$clear_output" "ALL secrets\|all secret" "Should indicate all secrets will be affected"
    assert_contains "$clear_output" "DELETE.*to confirm\|Type.*DELETE" "Should request specific confirmation text"
    
    # Verify secret still exists after cancelled operation
    assert_file_exists "$SECRETS_DIR/PROMPT_CLEAR_SECRET" "Secret file should still exist after cancelled clear"
}

# Test clear command actually deletes all secret files
test_secret_clear_deletes_files() {
    # Ensure secrets directory exists
    mkdir -p "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR/config"
    
    # Add multiple test secrets
    echo "file_clear_value_1" > "$SECRETS_DIR/FILE_CLEAR_SECRET_1"
    echo "file_clear_value_2" > "$SECRETS_DIR/FILE_CLEAR_SECRET_2"
    echo "file_clear_value_3" > "$SECRETS_DIR/FILE_CLEAR_SECRET_3"
    
    # Also add some non-secret files to ensure they're preserved
    mkdir -p "$SECRETS_DIR/config"
    echo "config data" > "$SECRETS_DIR/.config"
    echo "key data" > "$SECRETS_DIR/.key"
    
    # Count initial files
    local initial_file_count
    initial_file_count=$(find "$SECRETS_DIR" -type f | wc -l | tr -d ' ')
    assert_not_equals "0" "$initial_file_count" "Should have files before clearing"
    
    # Count initial secrets
    local initial_secret_count
    initial_secret_count=$(find "$SECRETS_DIR" -type f -name "FILE_CLEAR_SECRET_*" | wc -l | tr -d ' ')
    assert_equals "3" "$initial_secret_count" "Should have exactly 3 test secrets before clearing"
    
    # Clear all secrets with confirmation
    local clear_output
    clear_output=$(D secret clear <<< "DELETE")
    local clear_result=$?
    
    # Verify clear succeeded
    assert_equals "0" "$clear_result" "Clear command should succeed with confirmation"
    
    # Verify all secret files were deleted
    assert_file_not_exists "$SECRETS_DIR/FILE_CLEAR_SECRET_1" "First secret file should be deleted"
    assert_file_not_exists "$SECRETS_DIR/FILE_CLEAR_SECRET_2" "Second secret file should be deleted"
    assert_file_not_exists "$SECRETS_DIR/FILE_CLEAR_SECRET_3" "Third secret file should be deleted"
    
    # Count remaining secrets
    local remaining_secret_count
    remaining_secret_count=$(find "$SECRETS_DIR" -type f -name "FILE_CLEAR_SECRET_*" | wc -l | tr -d ' ')
    assert_equals "0" "$remaining_secret_count" "Should have no test secrets after clearing"
}
