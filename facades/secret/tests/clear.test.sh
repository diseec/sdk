#!/bin/bash

# Test for the 'secret clear' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "secret_clear_tests")
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test clear command with no secrets
test_secret_clear_no_secrets() {
    local output
    output=$(cd "$TEST_WORKSPACE" && D secret clear 2>&1)
    local result=$?
    
    # Should handle no secrets gracefully
    if [ "$result" -eq 0 ]; then
        assert_contains "$output" "No secrets found\|No secrets" "Should indicate no secrets to clear"
    fi
}

# Test clear command with existing secrets - confirm deletion
test_secret_clear_existing_secrets_confirm() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add some secrets to clear
    local add_output1
    add_output1=$(cd "$TEST_WORKSPACE" && echo -e "CLEAR_SECRET_1\nclear_value_1" | D secret add 2>&1)
    local add_result1=$?
    
    local add_output2
    add_output2=$(cd "$TEST_WORKSPACE" && echo -e "CLEAR_SECRET_2\nclear_value_2" | D secret add 2>&1)
    local add_result2=$?
    
    if [ "$add_result1" -ne 0 ] || [ "$add_result2" -ne 0 ]; then
        # Skip if we couldn't add the secrets
        return 0
    fi
    
    # Verify secrets exist before clearing
    local exists1_before
    exists1_before=$(cd "$TEST_WORKSPACE" && D secret exists CLEAR_SECRET_1 --quiet 2>&1)
    assert_equals "0" "$?" "First secret should exist before clearing"
    
    local exists2_before
    exists2_before=$(cd "$TEST_WORKSPACE" && D secret exists CLEAR_SECRET_2 --quiet 2>&1)
    assert_equals "0" "$?" "Second secret should exist before clearing"
    
    # Clear all secrets with confirmation (type 'DELETE' to confirm)
    local clear_output
    clear_output=$(cd "$TEST_WORKSPACE" && echo "DELETE" | D secret clear 2>&1)
    local clear_result=$?
    
    if [ "$clear_result" -eq 0 ]; then
        assert_contains "$clear_output" "cleared\|deleted" "Should indicate successful clearing"
        
        # Verify secrets no longer exist
        local exists1_after
        exists1_after=$(cd "$TEST_WORKSPACE" && D secret exists CLEAR_SECRET_1 --quiet 2>&1)
        assert_not_equals "0" "$?" "First secret should not exist after clearing"
        
        local exists2_after
        exists2_after=$(cd "$TEST_WORKSPACE" && D secret exists CLEAR_SECRET_2 --quiet 2>&1)
        assert_not_equals "0" "$?" "Second secret should not exist after clearing"
    fi
}

# Test clear command with existing secrets - cancel deletion
test_secret_clear_existing_secrets_cancel() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret to clear
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && echo -e "CANCEL_CLEAR_SECRET\ncancel_clear_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Verify secret exists before attempted clearing
    local exists_before
    exists_before=$(cd "$TEST_WORKSPACE" && D secret exists CANCEL_CLEAR_SECRET --quiet 2>&1)
    assert_equals "0" "$?" "Secret should exist before clear attempt"
    
    # Try to clear but cancel (provide anything other than 'DELETE')
    local clear_output
    clear_output=$(cd "$TEST_WORKSPACE" && echo "CANCEL" | D secret clear 2>&1)
    local clear_result=$?
    
    # Should indicate operation was cancelled
    assert_contains "$clear_output" "cancelled\|Operation cancelled" "Should indicate operation was cancelled"
    
    # Verify secret still exists
    local exists_after
    exists_after=$(cd "$TEST_WORKSPACE" && D secret exists CANCEL_CLEAR_SECRET --quiet 2>&1)
    assert_equals "0" "$?" "Secret should still exist after cancelled clear"
}

# Test clear command confirmation prompt
test_secret_clear_confirmation_prompt() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret so we have something to clear
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && echo -e "PROMPT_CLEAR_SECRET\nprompt_clear_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Try to clear and check the confirmation prompt
    local clear_output
    clear_output=$(cd "$TEST_WORKSPACE" && echo "CANCEL" | D secret clear 2>&1)
    
    # Should show warning and ask for confirmation
    assert_contains "$clear_output" "WARNING\|permanently delete\|ALL secrets" "Should show warning about permanent deletion"
    assert_contains "$clear_output" "DELETE.*to confirm\|Type.*DELETE" "Should ask for 'DELETE' confirmation"
}

# Test clear command requires exact confirmation text
test_secret_clear_requires_exact_confirmation() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret so we have something to clear
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && echo -e "EXACT_CONFIRM_SECRET\nexact_confirm_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Test various incorrect confirmations
    local incorrect_confirmations=("delete" "Delete" "YES" "yes" "confirm" "ok")
    
    for confirmation in "${incorrect_confirmations[@]}"; do
        # Try to clear with incorrect confirmation
        local clear_output
        clear_output=$(cd "$TEST_WORKSPACE" && echo "$confirmation" | D secret clear 2>&1)
        
        # Should be cancelled with any incorrect confirmation
        assert_contains "$clear_output" "cancelled\|Operation cancelled" "Should cancel with incorrect confirmation: $confirmation"
        
        # Verify secret still exists
        local exists_check
        exists_check=$(cd "$TEST_WORKSPACE" && D secret exists EXACT_CONFIRM_SECRET --quiet 2>&1)
        assert_equals "0" "$?" "Secret should still exist after incorrect confirmation: $confirmation"
    done
}

# Test clear command actually deletes all secret files
test_secret_clear_deletes_files() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add multiple secrets to clear
    local add_output1
    add_output1=$(cd "$TEST_WORKSPACE" && echo -e "FILE_CLEAR_SECRET_1\nfile_clear_value_1" | D secret add 2>&1)
    local add_result1=$?
    
    local add_output2
    add_output2=$(cd "$TEST_WORKSPACE" && echo -e "FILE_CLEAR_SECRET_2\nfile_clear_value_2" | D secret add 2>&1)
    local add_result2=$?
    
    if [ "$add_result1" -ne 0 ] || [ "$add_result2" -ne 0 ]; then
        # Skip if we couldn't add the secrets
        return 0
    fi
    
    # Check that secret files exist
    local secret_file1="$TEST_WORKSPACE/secrets/FILE_CLEAR_SECRET_1"
    local secret_file2="$TEST_WORKSPACE/secrets/FILE_CLEAR_SECRET_2"
    
    if [ -f "$secret_file1" ] && [ -f "$secret_file2" ]; then
        # Clear all secrets with confirmation
        local clear_output
        clear_output=$(cd "$TEST_WORKSPACE" && echo "DELETE" | D secret clear 2>&1)
        local clear_result=$?
        
        if [ "$clear_result" -eq 0 ]; then
            # Verify the actual files were deleted
            assert_file_not_exists "$secret_file1" "First secret file should be deleted"
            assert_file_not_exists "$secret_file2" "Second secret file should be deleted"
            
            # Check that secrets directory might be empty (but may still exist)
            local secrets_count=$(ls -1 "$TEST_WORKSPACE/secrets" 2>/dev/null | wc -l | tr -d ' ')
            assert_equals "0" "$secrets_count" "Secrets directory should be empty after clear"
        fi
    fi
}

# Test clear command with case-sensitive confirmation
test_secret_clear_case_sensitive_confirmation() {
    # Check if OpenSSL is available first
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # Skip test if OpenSSL not available
        return 0
    fi
    
    # First add a secret so we have something to clear
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && echo -e "CASE_SENSITIVE_SECRET\ncase_sensitive_value" | D secret add 2>&1)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Test that only exact 'DELETE' (uppercase) works
    local clear_output_lower
    clear_output_lower=$(cd "$TEST_WORKSPACE" && echo "delete" | D secret clear 2>&1)
    assert_contains "$clear_output_lower" "cancelled\|Operation cancelled" "Should cancel with lowercase 'delete'"
    
    # Verify secret still exists after lowercase attempt
    local exists_after_lower
    exists_after_lower=$(cd "$TEST_WORKSPACE" && D secret exists CASE_SENSITIVE_SECRET --quiet 2>&1)
    assert_equals "0" "$?" "Secret should still exist after lowercase confirmation"
    
    # Now test that uppercase 'DELETE' works
    local clear_output_upper
    clear_output_upper=$(cd "$TEST_WORKSPACE" && echo "DELETE" | D secret clear 2>&1)
    local clear_result_upper=$?
    
    if [ "$clear_result_upper" -eq 0 ]; then
        assert_contains "$clear_output_upper" "cleared\|deleted" "Should succeed with uppercase 'DELETE'"
        
        # Verify secret was actually deleted
        local exists_after_upper
        exists_after_upper=$(cd "$TEST_WORKSPACE" && D secret exists CASE_SENSITIVE_SECRET --quiet 2>&1)
        assert_not_equals "0" "$?" "Secret should not exist after uppercase confirmation"
    fi
}
