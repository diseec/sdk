#!/bin/bash

# Test for the 'secret remove' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "secret_remove_tests")
    
    # Ensure we have a writable secrets directory
    export ORIGINAL_SECRETS_DIR="$SECRETS_DIR"
    export SECRETS_DIR="$TEST_WORKSPACE/secrets"
    mkdir -p "$SECRETS_DIR" 2>/dev/null || {
        export SKIP_TESTS="Cannot create secrets directory - read-only filesystem"
        return 0
    }
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Restore original secrets directory
    export SECRETS_DIR="$ORIGINAL_SECRETS_DIR"
    
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test remove command requires secret name
test_secret_remove_requires_name() {
    local output
    output=$(d secret remove 2>&1)
    local result=$?
    
    # Should fail without secret name
    assert_not_equals "0" "$result" "Remove should fail without secret name"
    assert_contains "$output" "Secret name required\|Usage" "Should indicate secret name is required"
}

# Test remove command with non-existent secret
test_secret_remove_nonexistent_secret() {
    local output
    output=$(d secret remove NONEXISTENT_SECRET 2>&1)
    local result=$?
    
    # Should fail with non-existent secret
    assert_not_equals "0" "$result" "Remove should fail with non-existent secret"
    assert_contains "$output" "not found" "Should indicate secret not found"
}

# Test remove command with existing secret - confirm removal
test_secret_remove_existing_secret_confirm() {
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
    
    # First add a secret to remove
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
REMOVE_TEST_SECRET
remove_test_value
EOF
)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Verify secret exists before removal
    local exists_before
    exists_before=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret exists REMOVE_TEST_SECRET --quiet 2>&1)
    assert_equals "0" "$?" "Secret should exist before removal"
    
    # Remove the secret with confirmation (answer 'y' to prompt)
    local remove_output
    remove_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret remove REMOVE_TEST_SECRET <<EOF 2>&1
y
EOF
)
    local remove_result=$?
    
    if [ "$remove_result" -eq 0 ]; then
        assert_contains "$remove_output" "removed\|removed successfully" "Should indicate successful removal"
        
        # Verify secret no longer exists
        local exists_after
        exists_after=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret exists REMOVE_TEST_SECRET --quiet 2>&1)
        assert_not_equals "0" "$?" "Secret should not exist after removal"
    else
        # If remove failed, check if it was due to confirmation prompt
        assert_contains "$remove_output" "Are you sure\|confirm" "Should ask for confirmation"
    fi
}

# Test remove command with existing secret - cancel removal
test_secret_remove_existing_secret_cancel() {
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
    
    # First add a secret to remove
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
CANCEL_REMOVE_SECRET
cancel_remove_value
EOF
)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Verify secret exists before attempted removal
    local exists_before
    exists_before=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret exists CANCEL_REMOVE_SECRET --quiet 2>&1)
    assert_equals "0" "$?" "Secret should exist before removal attempt"
    
    # Try to remove the secret but cancel (answer 'n' to prompt)
    local remove_output
    remove_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret remove CANCEL_REMOVE_SECRET <<EOF 2>&1
n
EOF
)
    local remove_result=$?
    
    # Should indicate operation was cancelled
    assert_contains "$remove_output" "cancelled\|Operation cancelled" "Should indicate operation was cancelled"
    
    # Verify secret still exists
    local exists_after
    exists_after=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret exists CANCEL_REMOVE_SECRET --quiet 2>&1)
    assert_equals "0" "$?" "Secret should still exist after cancelled removal"
}
}

# Test remove command confirmation prompt format
test_secret_remove_confirmation_prompt() {
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
    
    # First add a secret to remove
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
PROMPT_TEST_SECRET
prompt_test_value
EOF
)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Try to remove and check the confirmation prompt contains the secret name
    local remove_output
    remove_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret remove PROMPT_TEST_SECRET <<EOF 2>&1
n
EOF
)
    
    # Should ask for confirmation and mention the specific secret name
    assert_contains "$remove_output" "Are you sure.*PROMPT_TEST_SECRET" "Should ask for confirmation with secret name"
}

# Test remove command with multiple aliases (rm, del, delete)
test_secret_remove_command_aliases() {
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
    
    # Test 'rm' alias
    local rm_output
    rm_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret rm NONEXISTENT_RM 2>&1)
    local rm_result=$?
    assert_not_equals "0" "$rm_result" "rm alias should work and fail for non-existent secret"
    
    # Test 'del' alias  
    local del_output
    del_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret del NONEXISTENT_DEL 2>&1)
    local del_result=$?
    assert_not_equals "0" "$del_result" "del alias should work and fail for non-existent secret"
    
    # Test 'delete' alias
    local delete_output
    delete_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret delete NONEXISTENT_DELETE 2>&1)
    local delete_result=$?
    assert_not_equals "0" "$delete_result" "delete alias should work and fail for non-existent secret"
}

# Test remove command actually deletes secret file
test_secret_remove_deletes_file() {
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
    
    # First add a secret to remove
    local add_output
    add_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
FILE_DELETE_SECRET
file_delete_value
EOF
)
    local add_result=$?
    
    if [ "$add_result" -ne 0 ]; then
        # Skip if we couldn't add the secret
        return 0
    fi
    
    # Check that secret file exists
    local secret_file="$SECRETS_DIR/FILE_DELETE_SECRET"
    if [ -f "$secret_file" ]; then
        # Remove the secret with confirmation
        local remove_output
        remove_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret remove FILE_DELETE_SECRET <<EOF 2>&1
y
EOF
)
        local remove_result=$?
        
        if [ "$remove_result" -eq 0 ]; then
            # Verify the actual file was deleted
            assert_file_not_exists "$secret_file" "Secret file should be deleted"
        fi
    fi
}
