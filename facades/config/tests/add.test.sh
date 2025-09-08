#!/bin/bash

# Test for the 'config add' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_add_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test adding to a new array
test_config_add_new_array() {
    # Add an item to a new array
    local output
    output=$(cd "$TEST_WORKSPACE" && D config --scope=user add new.array "item1")
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user add new.array \"item1\"" "Add command should succeed"
    
    # Verify the array was created and contains the item
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get new.array)
    
    # Expected output is exactly one item
    local expected_output="item1"
    
    # Direct exact comparison
    assert_equals "$expected_output" "$array_value" "Array should contain exactly item1"
}

# Test adding multiple items to an array
test_config_add_multiple_items() {
    # Add multiple items to an array
    cd "$TEST_WORKSPACE" && D config --scope=user add multiple.array "item1" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add multiple.array "item2" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add multiple.array "item3" > /dev/null
    
    # Get the full array output for verification
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get multiple.array)
    
    # Expected output is space-separated values
    local expected_output="item1 item2 item3"
    
    # Direct comparison of exact expected output
    assert_equals "$expected_output" "$array_value" "Array should contain exactly item1, item2, item3 in that order"
    
    # Verify we can iterate over the output
    local count=0
    for item in $array_value; do
        count=$((count + 1))
    done
    assert_equals "3" "$count" "Should be able to iterate over all array items"
}

# Test adding duplicate items
test_config_add_duplicate_items() {
    # Add an item twice
    cd "$TEST_WORKSPACE" && D config --scope=user add duplicate.array "item1" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add duplicate.array "item1" > /dev/null
    
    # Get the array value for verification
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get duplicate.array)
    
    # Expected output is exactly one item (no duplicates)
    local expected_output="item1"
    
    # Direct comparison of exact expected output
    assert_equals "$expected_output" "$array_value" "Duplicate items should be handled properly"
    
    # Count items to ensure only one exists
    local count=0
    for item in $array_value; do
        count=$((count + 1))
    done
    assert_equals "1" "$count" "Should have exactly one item after adding duplicates"
}

# Test adding to arrays in different scopes
test_config_add_different_scopes() {
    # Add items to arrays in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user add scope.array "user_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository add scope.array "repo_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context add scope.array "context_item" > /dev/null
    
    # Verify items were added to the correct arrays with exact expectations
    local user_array repo_array context_array
    user_array=$(cd "$TEST_WORKSPACE" && D config --scope=user get scope.array)
    repo_array=$(cd "$TEST_WORKSPACE" && D config --scope=repository get scope.array)
    context_array=$(cd "$TEST_WORKSPACE" && D config --scope=context get scope.array)
    
    # Expected outputs for each scope
    local expected_user="user_item"
    local expected_repo="repo_item"
    local expected_context="context_item"
    
    # Direct exact comparisons
    assert_equals "$expected_user" "$user_array" "User scope array should contain exactly user_item"
    assert_equals "$expected_repo" "$repo_array" "Repository scope array should contain exactly repo_item"
    assert_equals "$expected_context" "$context_array" "Context scope array should contain exactly context_item"
}

# Test adding to a nested array
test_config_add_nested_array() {
    # Add an item to a nested array
    cd "$TEST_WORKSPACE" && D config --scope=user add nested.config.array "nested_item" > /dev/null
    
    # Verify it was added correctly
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get nested.config.array)
    
    # Expected output is exactly one item
    local expected_output="nested_item"
    
    # Direct exact comparison
    assert_equals "$expected_output" "$array_value" "Nested array should contain exactly nested_item"
    
    # Verify the structure was created correctly by getting the print output
    # Using exact substrings we expect to find in the output
    local print_output
    print_output=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    
    # We need to verify the nested structure exists, but the exact format may vary
    # Check that "nested:" appears and "config:" appears after it
    local nested_line
    nested_line=$(echo "$print_output" | grep -n "nested:" | cut -d: -f1)
    local config_line
    config_line=$(echo "$print_output" | grep -n "config:" | cut -d: -f1)
    
    # Assert that both lines were found
    [ -n "$nested_line" ]
    assert_equals "$?" "0" "Output should contain nested: section"
    
    [ -n "$config_line" ]
    assert_equals "$?" "0" "Output should contain config: section"
    
    # Assert that config comes after nested (numerically greater line number)
    [ "$config_line" -gt "$nested_line" ]
    assert_equals "$?" "0" "The config section should be nested inside the nested section"
}
