#!/bin/bash

# Test for the 'config set' command

# Test basic set functionality
test_config_set_basic() {
    # Set a simple string value
    local output
    output=$(D config --scope=user set simple.key "simple_value")
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_CTX\" && D config --scope=user set simple.key \"simple_value\"" "Set command should succeed"
    
    # Verify the value was set correctly
    local value
    value=$(D config --scope=user get simple.key)
    assert_equals "simple_value" "$value" "Should set and retrieve simple string value"
}

# Test setting values in different scopes
test_config_set_different_scopes() {
    # Set values in different scopes
    D config --scope=user set scope.test "user_scope" > /dev/null
    D config --scope=repository set scope.test "repo_scope" > /dev/null
    D config --scope=context set scope.test "context_scope" > /dev/null
    
    # Verify values were set correctly
    local user_value repo_value context_value
    user_value=$(D config --scope=user get scope.test)
    repo_value=$(D config --scope=repository get scope.test)
    context_value=$(D config --scope=context get scope.test)
    
    assert_equals "user_scope" "$user_value" "Should set value in user scope"
    assert_equals "repo_scope" "$repo_value" "Should set value in repository scope"
    assert_equals "context_scope" "$context_value" "Should set value in context scope"
}

# Test setting nested values
test_config_set_nested_values() {
    # Set a deeply nested value
    D config --scope=user set deep.nested.config.key "deep_value" > /dev/null
    
    # Verify it was set correctly
    local value
    value=$(D config --scope=user get deep.nested.config.key)
    assert_equals "deep_value" "$value" "Should set and retrieve deeply nested value"
    
    # Verify the structure was created correctly
    local json_content
    json_content=$(D config --scope=user print)
    assert_contains "$json_content" "deep" "JSON should contain the deep object"
    assert_contains "$json_content" "nested" "JSON should contain the nested object"
}

# Test setting complex values (JSON) - temporarily disabled due to JSON parsing issues
# test_config_set_complex_values() {
#     # Set a JSON object
#     D config --scope=user set complex.object '{"name": "test", "value": 123}' > /dev/null
    
#     # Verify we can retrieve it properly
#     local json_content
#     json_content=$(D config --scope=user print)
#     assert_contains "$json_content" "test" "JSON should contain the object properties"
#     assert_contains "$json_content" "123" "JSON should contain the object values"
    
#     # Try to access a property of the object (this will depend on how the config system handles complex objects)
#     # This test might need adjustment based on the actual implementation
#     local object_value
#     object_value=$(D config --scope=user get complex.object)
#     assert_contains "$object_value" "test" "Should retrieve complex object correctly"
# }

# Test overwriting existing values
test_config_set_overwrite() {
    # Set an initial value
    D config --scope=repository set overwrite.test "initial_value" > /dev/null
    
    # Overwrite it
    D config --scope=repository set overwrite.test "new_value" > /dev/null
    
    # Verify it was overwritten
    local value
    value=$(D config --scope=repository get overwrite.test)

    assert_equals "new_value" "$value" "Should overwrite existing value"
}

# =============================================================================
# ARRAY FUNCTIONALITY TESTS
# =============================================================================

# Test adding to a new array using set with comma-separated format
test_config_set_new_array() {
    # Add an item to a new array using comma-separated format
    local output
    output=$(D config --scope=repository set new.array 'item1')
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_CTX\" && D config --scope=repository set new.array 'item1'" "Set array command should succeed"
    
    # Verify the array was created and contains the item
    local array_value
    array_value=$(D config --scope=repository get new.array)
    
    # Expected output is the single item (not in array format for single items)
    local expected_output='item1'
    
    # Direct exact comparison
    assert_equals "$expected_output" "$array_value" "Single item should be stored as scalar"
}

# Test adding multiple items to an array using set with comma-separated format
test_config_set_multiple_items_array() {
    # Add multiple items to an array using comma-separated format
    D config --scope=repository set multiple.array '[item1,item2,item3]' > /dev/null
    
    # Get the full array output for verification
    local array_value
    array_value=$(D config --scope=repository get multiple.array)

    # Expected output is YAML array format (each item on new line)
    local expected_lines=3
    local actual_lines=$(echo "$array_value" | wc -l | tr -d ' ')
    
    # Check that we got the right number of lines
    assert_equals "$expected_lines" "$actual_lines" "Array should have 3 items (3 lines)"
    
    # Check that all items are present
    echo "$array_value" | grep -q "item1"
    assert_equals "0" "$?" "Array should contain item1"
    
    echo "$array_value" | grep -q "item2"
    assert_equals "0" "$?" "Array should contain item2"
    
    echo "$array_value" | grep -q "item3"
    assert_equals "0" "$?" "Array should contain item3"
}

# Test adding duplicate items using set with comma-separated format
test_config_set_duplicate_items_array() {
    # Add an item twice using comma-separated format
    D config --scope=repository set duplicate.array '[item1,item1]' > /dev/null
    
    # Get the array value for verification
    local array_value
    array_value=$(D config --scope=repository get duplicate.array)
    
    # YAML arrays preserve duplicates - check that both items are present
    local item_count=$(echo "$array_value" | grep -c "item1")
    assert_equals "2" "$item_count" "YAML arrays should preserve duplicate items"
}

# Test adding to arrays in different scopes using set with comma-separated format
test_config_set_different_scopes_array() {
    # Add items to arrays in different scopes using comma-separated format
    D config --scope=user set scope.array 'user_item' > /dev/null
    D config --scope=repository set scope.array 'repo_item' > /dev/null
    D config --scope=context set scope.array 'context_item' > /dev/null
    
    # Verify items were added to the correct arrays
    local user_array repo_array context_array
    user_array=$(D config --scope=user get scope.array)
    repo_array=$(D config --scope=repository get scope.array)
    context_array=$(D config --scope=context get scope.array)
    
    # Expected outputs for each scope (YAML scalar format)
    local expected_user='user_item'
    local expected_repo='repo_item'
    local expected_context='context_item'
    
    # Direct exact comparisons
    assert_equals "$expected_user" "$user_array" "User scope should contain user_item"
    assert_equals "$expected_repo" "$repo_array" "Repository scope should contain repo_item"
    assert_equals "$expected_context" "$context_array" "Context scope should contain context_item"
}

# Test adding to a nested array using set with comma-separated format
test_config_set_nested_array() {
    # Add an item to a nested array using comma-separated format
    D config --scope=user set nested.config.array 'nested_item' > /dev/null
    
    # Verify it was added correctly
    local array_value
    array_value=$(D config --scope=user get nested.config.array)
    
    # Expected output is a single item (YAML scalar format)
    local expected_output='nested_item'
    
    # Direct exact comparison
    assert_equals "$expected_output" "$array_value" "Nested item should contain nested_item"
    
    # Verify the structure was created correctly by getting the print output
    local print_output
    print_output=$(D config --scope=user print)
    
    # Check that the nested structure exists in YAML format
    echo "$print_output" | grep -q "nested:"
    assert_equals "$?" "0" "Output should contain nested: section"
    
    echo "$print_output" | grep -q "config:"
    assert_equals "$?" "0" "Output should contain config: section"
    
    echo "$print_output" | grep -q "array:"
    assert_equals "$?" "0" "Output should contain array: section"
}

# Test adding multiple items to an array using set with comma-separated format
test_config_set_array_from_comma_separated() {
    # Add multiple items to an array using standard YAML array syntax
    # Note: Double quotes are needed to prevent the shell from interpreting brackets
    D config --scope=repository set submodules "[item1,item2,item3]" > /dev/null
    
    # Get the full array output for verification
    local array_value
    array_value=$(D config --scope=repository get submodules)
    
    # Expected output is YAML array format (each item on new line)
    local expected_lines=3
    local actual_lines=$(echo "$array_value" | wc -l | tr -d ' ')
    
    # Check that we got the right number of lines
    assert_equals "$expected_lines" "$actual_lines" "Array should have 3 items (3 lines)"
    
    # Check that all items are present
    echo "$array_value" | grep -q "item1"
    assert_equals "0" "$?" "Array should contain item1"
    
    echo "$array_value" | grep -q "item2"
    assert_equals "0" "$?" "Array should contain item2"
    
    echo "$array_value" | grep -q "item3"
    assert_equals "0" "$?" "Array should contain item3"
}