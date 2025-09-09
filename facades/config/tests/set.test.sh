#!/bin/bash

# Test for the 'config set' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_set_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test basic set functionality
test_config_set_basic() {
    ls -a;
    # Set a simple string value
    local output
    output=$(cd "$TEST_WORKSPACE" && D config --scope=user set simple.key "simple_value")
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user set simple.key \"simple_value\"" "Set command should succeed"
    
    # Verify the value was set correctly
    local value
    value=$(cd "$TEST_WORKSPACE" && D config --scope=user get simple.key)
    assert_equals "simple_value" "$value" "Should set and retrieve simple string value"
}

# Test setting values in different scopes
test_config_set_different_scopes() {
    # Set values in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user set scope.test "user_scope" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository set scope.test "repo_scope" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context set scope.test "context_scope" > /dev/null
    
    # Verify values were set correctly
    local user_value repo_value context_value
    user_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get scope.test)
    repo_value=$(cd "$TEST_WORKSPACE" && D config --scope=repository get scope.test)
    context_value=$(cd "$TEST_WORKSPACE" && D config --scope=context get scope.test)
    
    assert_equals "user_scope" "$user_value" "Should set value in user scope"
    assert_equals "repo_scope" "$repo_value" "Should set value in repository scope"
    assert_equals "context_scope" "$context_value" "Should set value in context scope"
}

# Test setting nested values
test_config_set_nested_values() {
    # Set a deeply nested value
    cd "$TEST_WORKSPACE" && D config --scope=user set deep.nested.config.key "deep_value" > /dev/null
    
    # Verify it was set correctly
    local value
    value=$(cd "$TEST_WORKSPACE" && D config --scope=user get deep.nested.config.key)
    assert_equals "deep_value" "$value" "Should set and retrieve deeply nested value"
    
    # Verify the structure was created correctly
    local json_content
    json_content=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    assert_contains "$json_content" "deep" "JSON should contain the deep object"
    assert_contains "$json_content" "nested" "JSON should contain the nested object"
}

# Test setting complex values (JSON)
test_config_set_complex_values() {
    # Set a JSON object
    cd "$TEST_WORKSPACE" && D config --scope=user set complex.object '{"name": "test", "value": 123}' > /dev/null
    
    # Verify we can retrieve it properly
    local json_content
    json_content=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    assert_contains "$json_content" "test" "JSON should contain the object properties"
    assert_contains "$json_content" "123" "JSON should contain the object values"
    
    # Try to access a property of the object (this will depend on how the config system handles complex objects)
    # This test might need adjustment based on the actual implementation
    local object_value
    object_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get complex.object)
    assert_contains "$object_value" "test" "Should retrieve complex object correctly"
}

# Test overwriting existing values
test_config_set_overwrite() {
    # Set an initial value
    cd "$TEST_WORKSPACE" && D config --scope=user set overwrite.test "initial_value" > /dev/null
    
    # Overwrite it
    cd "$TEST_WORKSPACE" && D config --scope=user set overwrite.test "new_value" > /dev/null
    
    # Verify it was overwritten
    local value
    value=$(cd "$TEST_WORKSPACE" && D config --scope=user get overwrite.test)
    assert_equals "new_value" "$value" "Should overwrite existing value"
}

# =============================================================================
# ARRAY FUNCTIONALITY TESTS (merged from add.test.sh)
# =============================================================================

# Test adding to a new array using set with array syntax
test_config_set_new_array() {
    # Add an item to a new array using set with array syntax
    local output
    output=$(cd "$TEST_WORKSPACE" && D config --scope=user set new.array '["item1"]')
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user set new.array '[\"item1\"]'" "Set array command should succeed"
    
    # Verify the array was created and contains the item
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get new.array)
    
    # Expected output is exactly one item
    local expected_output="item1"
    
    # Direct exact comparison
    assert_equals "$expected_output" "$array_value" "Array should contain exactly item1"
}

# Test adding multiple items to an array using set with array syntax
test_config_set_multiple_items_array() {
    # Add multiple items to an array using set with array syntax
    cd "$TEST_WORKSPACE" && D config --scope=user set multiple.array '["item1", "item2", "item3"]' > /dev/null
    
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

# Test adding duplicate items using set with array syntax
test_config_set_duplicate_items_array() {
    # Add an item twice using set with array syntax
    cd "$TEST_WORKSPACE" && D config --scope=user set duplicate.array '["item1", "item1"]' > /dev/null
    
    # Get the array value for verification
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get duplicate.array)
    
    # Expected output is exactly one item (no duplicates)
    local expected_output="item1 item1"
    
    # Direct comparison of exact expected output - the system may or may not dedupe
    assert_equals "$expected_output" "$array_value" "Duplicate items should be handled properly"
}

# Test adding to arrays in different scopes using set with array syntax
test_config_set_different_scopes_array() {
    # Add items to arrays in different scopes using set with array syntax
    cd "$TEST_WORKSPACE" && D config --scope=user set scope.array '["user_item"]' > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository set scope.array '["repo_item"]' > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context set scope.array '["context_item"]' > /dev/null
    
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

# Test adding to a nested array using set with array syntax
test_config_set_nested_array() {
    # Add an item to a nested array using set with array syntax
    cd "$TEST_WORKSPACE" && D config --scope=user set nested.config.array '["nested_item"]' > /dev/null
    
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
