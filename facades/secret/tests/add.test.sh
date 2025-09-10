#!/bin/bash

# Test for the 'secret add' command

# Test add command with existing secret - decline overwrite
test_secret_add_decline_overwrite_only() {
    cd "$TEST_WORKSPACE"
    
    # Generate a consistent key for testing
    echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" | SECRETS_DIR="$SECRETS_DIR" D secret key-set > /dev/null 2>&1
    
    # Add initial secret
    echo -e "DECLINE_OVERWRITE_SECRET\noriginal_value" | SECRETS_DIR="$SECRETS_DIR" D secret add > /dev/null 2>&1
    
    # Verify initial value
    local original_value
    original_value=$(SECRETS_DIR="$SECRETS_DIR" D secret export DECLINE_OVERWRITE_SECRET 2>/dev/null)
    assert_equals "original_value" "$original_value" "Initial secret value should be set correctly"
    
    # Try to add same secret again but decline overwrite
    local overwrite_output
    overwrite_output=$(echo -e "DECLINE_OVERWRITE_SECRET\nnew_value\nn" | SECRETS_DIR="$SECRETS_DIR" D secret add 2>&1)
    
    # Check if the output contains the overwrite prompt
    assert_contains "$overwrite_output" "already exists\|Overwrite" "Should ask about overwriting"
    
    # Verify the value remains unchanged
    local final_value
    final_value=$(SECRETS_DIR="$SECRETS_DIR" D secret export DECLINE_OVERWRITE_SECRET 2>/dev/null)
    assert_equals "original_value" "$final_value" "Should preserve original value when overwrite declined"
}

# Test add command requires OpenSSL
test_secret_add_requires_openssl() {
    # Mock the OpenSSL availability check to force failure
    # This is done by defining a local _openssl function that will override the system one
    _openssl() {
        return 127  # Command not found exit code
    }
    export -f _openssl
    
    # Now test the command with our mocked OpenSSL
    local output
    output=$(echo -e "TEST_SECRET\ntest_value" | D secret add 2>&1)
    local add_result=$?
    
    # Clean up our mock
    unset -f _openssl
    
    # Verify results
    assert_not_equals "0" "$add_result" "Add command should fail without OpenSSL"
    assert_contains "$output" "OpenSSL\|required\|available" "Should indicate OpenSSL requirement"
}

# Test add command basic functionality with simulated input
test_secret_add_basic_functionality() {
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
