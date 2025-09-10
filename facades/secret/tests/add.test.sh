#!/bin/bash

# Test for the 'secret add' command

# Test add command with existing secret - decline overwrite
test_secret_add_decline_overwrite_only() {
    # Add initial secret
    local add_output
    add_output=$(D secret add <<EOF 2>&1
DECLINE_OVERWRITE_SECRET
original_value
EOF
)
    
    # Verify the initial secret was added successfully
    assert_contains "$add_output" "added successfully" "Initial secret should be added successfully"
    
    # Verify initial value is correct through export
    local original_value
    original_value=$(D secret export DECLINE_OVERWRITE_SECRET 2>/dev/null)
    assert_equals "original_value" "$original_value" "Initial secret value should be set correctly"
    
    # Try to add same secret again but decline overwrite
    local overwrite_output
    overwrite_output=$(D secret add <<EOF 2>&1
DECLINE_OVERWRITE_SECRET
new_value
n
EOF
)
    
    # Check if the output contains the overwrite prompt
    assert_contains "$overwrite_output" "already exists" "Should warn that secret already exists"
    assert_contains "$overwrite_output" "Overwrite" "Should ask about overwriting"
    
    # Verify the original value is preserved
    local final_value
    final_value=$(D secret export DECLINE_OVERWRITE_SECRET 2>/dev/null)
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
    assert_contains "$output" "OpenSSL" "Should mention OpenSSL"
    assert_contains "$output" "required" "Should indicate OpenSSL is required"
}

# Test add command basic functionality with simulated input
test_secret_add_basic_functionality() {
    # Test interactive input by providing input through heredoc
    local output
    output=$(D secret add <<EOF 2>&1
TEST_SECRET
test_value_123
EOF
)
    
    # Verify the command succeeded and reported success
    assert_equals "0" "$?" "Add command should succeed"
    assert_contains "$output" "added successfully" "Should indicate successful addition"
    
    # Verify the secret was actually added and can be exported
    local export_output
    export_output=$(D secret export TEST_SECRET 2>/dev/null)
    assert_equals "test_value_123" "$export_output" "Should be able to export the added secret with correct value"
}

# Test add command with existing secret (overwrite scenario)
test_secret_add_overwrite_existing() {
    # First add a secret
    local output1
    output1=$(D secret add <<EOF 2>&1
EXISTING_SECRET
original_value
EOF
)
    
    # Verify the initial secret was added successfully
    assert_equals "0" "$?" "Initial secret addition should succeed"
    assert_contains "$output1" "added successfully" "Should indicate successful initial addition"
    
    # Verify initial value through export
    local initial_value
    initial_value=$(D secret export EXISTING_SECRET 2>/dev/null)
    assert_equals "original_value" "$initial_value" "Initial secret value should be set correctly"
    
    # Try to add same secret again with "yes" to overwrite
    local output2
    output2=$(D secret add <<EOF 2>&1
EXISTING_SECRET
new_value
y
EOF
)
    
    # Verify the command succeeded and asked about overwriting
    assert_equals "0" "$?" "Overwrite operation should succeed"
    assert_contains "$output2" "already exists" "Should warn that secret already exists"
    assert_contains "$output2" "Overwrite" "Should ask about overwriting"
    assert_contains "$output2" "added successfully" "Should indicate successful overwrite"
    
    # Verify the value was actually updated through export
    local new_value
    new_value=$(D secret export EXISTING_SECRET 2>/dev/null)
    assert_equals "new_value" "$new_value" "Should have updated to new value after overwrite"
}

# Test add command with empty secret name
test_secret_add_empty_name() {
    # Test with empty name input - the command should prompt again or fail
    local output
    output=$(D secret add <<EOF 2>&1

test_value
EOF
)
    
    # Verify command handled empty name appropriately
    assert_not_equals "0" "$?" "Command should not succeed with empty name"
    assert_not_equals "" "$output" "Should provide some response to empty name"
    assert_contains "$output" "name" "Should indicate a name is required"
}

# Test add command with empty secret value
test_secret_add_empty_value() {
    # Test with empty value input
    local output
    output=$(timeout 5 bash -c "echo -e 'EMPTY_VALUE_SECRET\n' | D secret add" 2>&1)
    
    # Verify command handled empty value appropriately
    assert_not_equals "0" "$?" "Command should not succeed with empty value"
    assert_not_equals "" "$output" "Should provide some response to empty value"
    assert_contains "$output" "value" "Should indicate a value is required"
}

# Test add command creates secrets directory
test_secret_add_creates_secrets_directory() {
    # First, remove the secrets directory if it exists
    if [ -d "$SECRETS_DIR" ]; then
        rm -rf "$SECRETS_DIR"
    fi
    
    # Verify the directory doesn't exist
    assert_file_not_exists "$SECRETS_DIR" "Secrets directory should not exist before test"
    
    # Run a command that should create the directory
    local output
    output=$(echo -e "DIR_CREATION_TEST\ntest_value" | D secret add 2>&1)
    
    # Verify the directory was created
    assert_file_exists "$SECRETS_DIR" "Secret add command should create secrets directory"
    assert_equals "0" "$?" "Add command should succeed"
    assert_contains "$output" "added successfully" "Should indicate successful addition"
    
    # Verify the secret exists and is correct
    local value
    value=$(D secret export DIR_CREATION_TEST 2>/dev/null)
    assert_equals "test_value" "$value" "Secret should be stored correctly"
}
