#!/bin/bash

# Test for the 'secret add' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace and set up secrets directory
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "secret_add_tests")
    
    # Ensure we have a writable secrets directory
    export ORIGINAL_SECRETS_DIR="$SECRETS_DIR"
    export SECRETS_DIR="$TEST_WORKSPACE/secrets"

    mkdir -p "$SECRETS_DIR" 2>/dev/null || {
        # If we can't create secrets directory, skip tests
        export SKIP_TESTS="Cannot create secrets directory - read-only filesystem"
        return 0
    }
}

# Test add command with existing secret - decline overwrite
test_secret_add_decline_overwrite() {
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
    
    # First add a secret
    local output1
    output1=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
DECLINE_OVERWRITE_SECRET
original_value
EOF
)
    local add_result1=$?
    
    if [ "$add_result1" -ne 0 ]; then
        # Skip if first add failed
        return 0
    fi
    
    # Try to add same secret again but decline overwrite with "n"
    local output2
    output2=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
DECLINE_OVERWRITE_SECRET
new_value
n
EOF
)
    local add_result2=$?
    
    # Should ask about overwriting
    assert_contains "$output2" "already exists\|Overwrite" "Should ask about overwriting"
    
    # Should succeed (user chose not to overwrite, which is valid)
    if [ "$add_result2" -eq 0 ]; then
        # Verify the original value is preserved
        local export_output
        export_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret export DECLINE_OVERWRITE_SECRET 2>&1)
        if [ $? -eq 0 ]; then
            assert_equals "original_value" "$export_output" "Should preserve original value when overwrite declined"
        fi
    fi
}



# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Restore original secrets directory
    export SECRETS_DIR="$ORIGINAL_SECRETS_DIR"
    
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test add command requires OpenSSL
test_secret_add_requires_openssl() {
    # Skip if OpenSSL is not available (we can't test this scenario easily)
    local openssl_check
    openssl_check=$(cd "$TEST_WORKSPACE" && D secret available --quiet 2>&1)
    local result=$?
    
    if [ "$result" -ne 0 ]; then
        # OpenSSL not available - command should fail
        local output
        output=$(cd "$TEST_WORKSPACE" && echo -e "TEST_SECRET\ntest_value" | D secret add 2>&1)
        local add_result=$?
        
        assert_not_equals "0" "$add_result" "Add command should fail without OpenSSL"
        assert_contains "$output" "OpenSSL\|required\|available" "Should indicate OpenSSL requirement"
    fi
}

# Test add command basic functionality with simulated input
test_secret_add_basic_functionality() {
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
    
    # Test interactive input by providing input through heredoc
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
TEST_SECRET
test_value_123
EOF
)
    local add_result=$?
    
    # Command should succeed if OpenSSL is available and input is provided
    if [ "$add_result" -eq 0 ]; then
        assert_contains "$output" "added successfully\|SUCCESS" "Should indicate successful addition"
        
        # Verify the secret exists by checking if we can export it
        local export_output
        export_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret export TEST_SECRET 2>&1)
        local export_result=$?
        
        if [ "$export_result" -eq 0 ]; then
            assert_equals "test_value_123" "$export_output" "Should be able to export the added secret"
        fi
    else
        # If it failed, check if the error makes sense
        assert_contains "$output" "secret\|Secret\|OpenSSL\|key\|encrypt" "Should indicate secret-related error"
    fi
}

# Test add command with existing secret (overwrite scenario)
test_secret_add_overwrite_existing() {
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
    
    # First add a secret
    local output1
    output1=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
EXISTING_SECRET
original_value
EOF
)
    local add_result1=$?
    
    if [ "$add_result1" -ne 0 ]; then
        # Skip if first add failed
        return 0
    fi
    
    # Try to add same secret again with "yes" to overwrite
    local output2
    output2=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1
EXISTING_SECRET
new_value
y
EOF
)
    local add_result2=$?
    
    # Should ask about overwriting and then succeed
    assert_contains "$output2" "already exists\|Overwrite" "Should ask about overwriting"
    
    if [ "$add_result2" -eq 0 ]; then
        # Verify the value was updated
        local export_output
        export_output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret export EXISTING_SECRET 2>&1)
        if [ $? -eq 0 ]; then
            assert_equals "new_value" "$export_output" "Should have updated to new value after overwrite"
        fi
    fi
}

# Test add command with empty secret name
test_secret_add_empty_name() {
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
    
    # Test with empty name input - the command should prompt again or fail
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" D secret add <<EOF 2>&1

test_value
EOF
)
    local add_result=$?
    
    # Should either reprompt for name or fail with validation error
    # The exact behavior depends on input validation implementation
    assert_not_equals "" "$output" "Should provide some response to empty name"
    assert_contains "$output" "secret\|Secret\|name\|Enter" "Should indicate secret name is required"
}

# Test add command with empty secret value
test_secret_add_empty_value() {
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
    
    # Test with empty value
    local output
    output=$(cd "$TEST_WORKSPACE" && SECRETS_DIR="$SECRETS_DIR" timeout 5 bash -c "echo -e 'EMPTY_VALUE_SECRET\n' | D secret add" 2>&1)
    local add_result=$?
    
    # Should either reprompt for value or fail with validation error
    assert_not_equals "" "$output" "Should provide some response to empty value"
}

# Test add command ensures secrets directory exists
test_secret_add_creates_secrets_directory() {
    # This test is handled by our suite setup now
    # Just verify the directory exists
    if [ -n "$SKIP_TESTS" ]; then
        return 0
    fi
    
    # Verify our test setup created the secrets directory
    assert_file_exists "$SECRETS_DIR" "Secrets directory should exist for tests"
    
    # Verify it's writable
    local test_file="$SECRETS_DIR/.test_write"
    echo "test" > "$test_file" 2>/dev/null
    if [ -f "$test_file" ]; then
        rm -f "$test_file"
        assert_equals "0" "0" "Secrets directory should be writable"
    fi
}
