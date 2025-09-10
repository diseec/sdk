#!/bin/bash

# Test for the 'secret clear' command

# Test clear command with no secrets
test_secret_clear_no_secrets() {
    # Ensure no secrets exist
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # Run clear command
    local output
    output=$(D secret clear <<< "DELETE" 2>&1)
    local result=$?
    
    # Verify command succeeds with appropriate message
    assert_equals "0" "$result" "Clear command should succeed even with no secrets"
    assert_contains "$output" "No secrets found\|No secrets to clear\|Nothing to clear" "Should indicate no secrets to clear"
    
    # Verify secrets directory still exists but is empty
    assert_file_exists "$SECRETS_DIR" "Secrets directory should still exist after clear"
    assert_directory_empty "$SECRETS_DIR" "Secrets directory should be empty after clear"
}

# Test clear command with existing secrets - confirm deletion
test_secret_clear_existing_secrets_confirm() {
    # Clean up environment
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # Add two test secrets
    echo "clear_value_1" > "$SECRETS_DIR/CLEAR_SECRET_1"
    echo "clear_value_2" > "$SECRETS_DIR/CLEAR_SECRET_2"
    
    # Verify secrets exist before clearing
    assert_file_exists "$SECRETS_DIR/CLEAR_SECRET_1" "First secret file should exist before clearing"
    assert_file_exists "$SECRETS_DIR/CLEAR_SECRET_2" "Second secret file should exist before clearing"
    
    # Clear all secrets with confirmation
    local clear_output
    clear_output=$(D secret clear <<< "DELETE" 2>&1)
    local clear_result=$?
    
    # Verify clear command succeeded
    assert_equals "0" "$clear_result" "Clear command should succeed with confirmation"
    assert_contains "$clear_output" "cleared\|deleted\|removed" "Should indicate successful clearing"
    
    # Verify secrets directory is empty after clearing
    assert_file_exists "$SECRETS_DIR" "Secrets directory should still exist after clearing"
    assert_directory_empty "$SECRETS_DIR" "Secrets directory should be empty after clearing"
    
    # Verify specific secret files no longer exist
    assert_not_file_exists "$SECRETS_DIR/CLEAR_SECRET_1" "First secret file should be deleted"
    assert_not_file_exists "$SECRETS_DIR/CLEAR_SECRET_2" "Second secret file should be deleted"
}

# Test clear command with existing secrets - cancel deletion
test_secret_clear_existing_secrets_cancel() {
    # Clean up environment
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # Add a test secret
    echo "cancel_clear_value" > "$SECRETS_DIR/CANCEL_CLEAR_SECRET"
    
    # Verify secret exists before attempted clearing
    assert_file_exists "$SECRETS_DIR/CANCEL_CLEAR_SECRET" "Secret file should exist before clear attempt"
    
    # Try to clear but cancel (provide anything other than 'DELETE')
    local clear_output
    clear_output=$(D secret clear <<< "CANCEL" 2>&1)
    local clear_result=$?
    
    # Verify operation was cancelled
    assert_not_equals "0" "$clear_result" "Clear command should fail when cancelled"
    assert_contains "$clear_output" "cancelled\|aborted\|Operation cancelled" "Should indicate operation was cancelled"
    
    # Verify secret still exists after cancelled operation
    assert_file_exists "$SECRETS_DIR/CANCEL_CLEAR_SECRET" "Secret file should still exist after cancelled clear"
    
    # Verify secret content is unchanged
    local secret_content
    secret_content=$(cat "$SECRETS_DIR/CANCEL_CLEAR_SECRET")
    assert_equals "cancel_clear_value" "$secret_content" "Secret content should be unchanged after cancelled clear"
}

# Test clear command confirmation prompt
test_secret_clear_confirmation_prompt() {
    # Clean up environment
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # Add a test secret
    echo "prompt_clear_value" > "$SECRETS_DIR/PROMPT_CLEAR_SECRET"
    
    # Capture output to check the confirmation prompt
    local clear_output
    clear_output=$(D secret clear <<< "CANCEL" 2>&1)
    
    # Verify appropriate warnings and confirmation request
    assert_contains "$clear_output" "WARNING\|warning\|caution" "Should show warning message"
    assert_contains "$clear_output" "permanently delete\|will be deleted\|cannot be undone" "Should warn about permanent deletion"
    assert_contains "$clear_output" "ALL secrets\|all secret" "Should indicate all secrets will be affected"
    assert_contains "$clear_output" "DELETE.*to confirm\|Type.*DELETE" "Should request specific confirmation text"
    
    # Verify secret still exists after cancelled operation
    assert_file_exists "$SECRETS_DIR/PROMPT_CLEAR_SECRET" "Secret file should still exist after cancelled clear"
}

# Test clear command requires exact confirmation text
test_secret_clear_requires_exact_confirmation() {
    # Clean up environment
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # Add a test secret
    echo "exact_confirm_value" > "$SECRETS_DIR/EXACT_CONFIRM_SECRET"
    
    # Define array of incorrect confirmations to test
    local incorrect_confirmations=("delete" "Delete" "YES" "yes" "confirm" "ok" "CONFIRM" "REMOVE" "ERASE")
    
    # Test each incorrect confirmation
    for confirmation in "${incorrect_confirmations[@]}"; do
        # Try to clear with incorrect confirmation
        local clear_output
        clear_output=$(D secret clear <<< "$confirmation" 2>&1)
        local clear_result=$?
        
        # Verify operation was cancelled
        assert_not_equals "0" "$clear_result" "Clear should fail with incorrect confirmation: '$confirmation'"
        assert_contains "$clear_output" "cancelled\|aborted\|Operation cancelled" "Should cancel with incorrect confirmation: '$confirmation'"
        
        # Verify secret still exists
        assert_file_exists "$SECRETS_DIR/EXACT_CONFIRM_SECRET" "Secret should still exist after incorrect confirmation: '$confirmation'"
    done
    
    # Verify that the correct confirmation works
    local correct_output
    correct_output=$(D secret clear <<< "DELETE" 2>&1)
    local correct_result=$?
    
    # Verify clear succeeded with correct confirmation
    assert_equals "0" "$correct_result" "Clear should succeed with correct 'DELETE' confirmation"
    assert_contains "$correct_output" "cleared\|deleted\|removed" "Should indicate successful clearing with correct confirmation"
    
    # Verify secret was deleted
    assert_not_file_exists "$SECRETS_DIR/EXACT_CONFIRM_SECRET" "Secret should be deleted after correct confirmation"
}

# Test clear command actually deletes all secret files
test_secret_clear_deletes_files() {
    # Clean up environment
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
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
    clear_output=$(D secret clear <<< "DELETE" 2>&1)
    local clear_result=$?
    
    # Verify clear succeeded
    assert_equals "0" "$clear_result" "Clear command should succeed with confirmation"
    
    # Verify all secret files were deleted
    assert_not_file_exists "$SECRETS_DIR/FILE_CLEAR_SECRET_1" "First secret file should be deleted"
    assert_not_file_exists "$SECRETS_DIR/FILE_CLEAR_SECRET_2" "Second secret file should be deleted"
    assert_not_file_exists "$SECRETS_DIR/FILE_CLEAR_SECRET_3" "Third secret file should be deleted"
    
    # Count remaining secrets
    local remaining_secret_count
    remaining_secret_count=$(find "$SECRETS_DIR" -type f -name "FILE_CLEAR_SECRET_*" | wc -l | tr -d ' ')
    assert_equals "0" "$remaining_secret_count" "Should have no test secrets after clearing"
}

# Test clear command with case-sensitive confirmation
test_secret_clear_case_sensitive_confirmation() {
    # Clean up environment
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # Add a test secret
    echo "case_sensitive_value" > "$SECRETS_DIR/CASE_SENSITIVE_SECRET"
    
    # Test lowercase 'delete' (should fail)
    local lower_output
    lower_output=$(D secret clear <<< "delete" 2>&1)
    local lower_result=$?
    
    # Verify lowercase confirmation fails
    assert_not_equals "0" "$lower_result" "Clear should fail with lowercase 'delete'"
    assert_contains "$lower_output" "cancelled\|aborted\|Operation cancelled" "Should cancel with lowercase 'delete'"
    
    # Verify secret still exists after lowercase attempt
    assert_file_exists "$SECRETS_DIR/CASE_SENSITIVE_SECRET" "Secret should still exist after lowercase confirmation"
    
    # Test uppercase 'DELETE' (should succeed)
    local upper_output
    upper_output=$(D secret clear <<< "DELETE" 2>&1)
    local upper_result=$?
    
    # Verify uppercase confirmation succeeds
    assert_equals "0" "$upper_result" "Clear should succeed with uppercase 'DELETE'"
    assert_contains "$upper_output" "cleared\|deleted\|removed" "Should indicate successful clearing with uppercase 'DELETE'"
    
    # Verify secret was deleted after uppercase confirmation
    assert_not_file_exists "$SECRETS_DIR/CASE_SENSITIVE_SECRET" "Secret should be deleted after uppercase confirmation"
}

# Test clear command preserves secrets directory
test_secret_clear_preserves_directory() {
    # Clean up environment
    rm -rf "$SECRETS_DIR"
    mkdir -p "$SECRETS_DIR"
    
    # Add a test secret
    echo "preserve_dir_value" > "$SECRETS_DIR/PRESERVE_DIR_SECRET"
    
    # Verify directory and secret exist initially
    assert_file_exists "$SECRETS_DIR" "Secrets directory should exist initially"
    assert_file_exists "$SECRETS_DIR/PRESERVE_DIR_SECRET" "Secret file should exist initially"
    
    # Clear secrets
    local clear_output
    clear_output=$(D secret clear <<< "DELETE" 2>&1)
    local clear_result=$?
    
    # Verify clear succeeded
    assert_equals "0" "$clear_result" "Clear command should succeed"
    
    # Verify directory still exists but secret is gone
    assert_file_exists "$SECRETS_DIR" "Secrets directory should still exist after clearing"
    assert_not_file_exists "$SECRETS_DIR/PRESERVE_DIR_SECRET" "Secret file should be deleted"
    assert_directory_empty "$SECRETS_DIR" "Secrets directory should be empty after clearing"
}
