#!/bin/bash

# Test for the 'config rem|remove' command

# Suite setup - runs once before all tests in this file
setup_test() {
    # Initialize config
    D config init > /dev/null
    
    # Set up some test arrays using comma-separated format
    D config --scope=user set simple.array 'item1,item2,item3' > /dev/null
    D config --scope=user set nested.array 'item1,item2,item3' > /dev/null
    
    # Set up arrays in different scopes using comma-separated format
    D config --scope=user set scope.array 'user_item' > /dev/null
    D config --scope=repository set scope.array 'repo_item' > /dev/null
    D config --scope=context set scope.array 'context_item' > /dev/null
}
# Test removing an item from an array
test_config_remove_item() {
    # Remove an item from the array
    local output
    output=$(D config --scope=user remove simple.array "item2")
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user remove simple.array \"item2\"" "Remove command should succeed"
    
    # Verify the item was removed
    local array_value
    array_value=$(D config --scope=user get simple.array)
    assert_contains "$array_value" "item1" "Array should still contain first item"
    assert_not_contains "$array_value" "item2" "Array should not contain removed item"
    assert_contains "$array_value" "item3" "Array should still contain third item"
}

# Test removing the last item from an array
test_config_remove_last_item() {
    # Create a single-item array
    D config --scope=user set single.array 'only_item' > /dev/null
    
    # Remove the only item
    D config --scope=user remove single.array "only_item" > /dev/null
    
    # Verify what happens when the last item is removed
    # This test might need adjustment based on the actual implementation
    # Some systems might keep an empty array, others might remove the key entirely
    
    local array_exists
    array_exists=$(D config --scope=user get single.array 2>/dev/null || echo "not_found")
    
    # Adjust this assertion based on expected behavior
    # Here we're assuming an empty array is kept
    assert_not_equals "not_found" "$array_exists" "Array should still exist even when empty"
    assert_matches "$array_exists" "\\[\\s*\\]" "Array should be empty after removing the last item"
}

# Test removing a non-existent item
test_config_remove_nonexistent_item() {
    # Try to remove an item that doesn't exist
    local result
    result=$(D config --scope=user remove simple.array "nonexistent_item" 2>&1)
    
    # Verify behavior for non-existent items
    # This might be implementation-dependent
    # Some systems might fail, others might just ignore it
    
    # Check that the array remains unchanged
    local array_value
    array_value=$(D config --scope=user get simple.array)
    assert_contains "$array_value" "item1" "Array should remain unchanged"
    assert_contains "$array_value" "item3" "Array should remain unchanged"
}

# Test removing from arrays in different scopes
test_config_remove_different_scopes() {
    # Remove items from arrays in different scopes
    D config --scope=user remove scope.array "user_item" > /dev/null
    D config --scope=repository remove scope.array "repo_item" > /dev/null
    D config --scope=context remove scope.array "context_item" > /dev/null
    
    # Verify items were removed from the correct arrays
    local user_array repo_array context_array
    user_array=$(D config --scope=user get scope.array 2>/dev/null || echo "not_found")
    repo_array=$(D config --scope=repository get scope.array 2>/dev/null || echo "not_found")
    context_array=$(D config --scope=context get scope.array 2>/dev/null || echo "not_found")
    
    # Check each array is now empty or removed
    assert_not_contains "$user_array" "user_item" "User scope array should not contain removed item"
    assert_not_contains "$repo_array" "repo_item" "Repository scope array should not contain removed item"
    assert_not_contains "$context_array" "context_item" "Context scope array should not contain removed item"
}

# Test removing an item from a nested array
test_config_remove_nested_array() {
    # Remove an item from a nested array
    D config --scope=user remove nested.array "item2" > /dev/null
    
    # Verify it was removed correctly
    local array_value
    array_value=$(D config --scope=user get nested.array)
    assert_contains "$array_value" "item1" "Nested array should still contain first item"
    assert_not_contains "$array_value" "item2" "Nested array should not contain removed item"
    assert_contains "$array_value" "item3" "Nested array should still contain third item"
}

# =============================================================================
# KEY DELETION FUNCTIONALITY TESTS (merged from delete.test.sh)
# =============================================================================

# Test deleting a simple key using remove command without value parameter
test_config_remove_delete_simple_key() {
    # Set up a simple key
    D config --scope=user set simple.key "simple_value" > /dev/null
    
    # Delete the key using remove command without value parameter
    local output
    output=$(D config --scope=user remove simple.key)
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user remove simple.key" "Remove command should succeed for key deletion"
    
    # Verify the key was deleted
    local key_exists
    key_exists=$(D config --scope=user get simple.key 2>/dev/null || echo "not_found")
    assert_equals "not_found" "$key_exists" "Key should be deleted"
}

# Test deleting a nested key
test_config_remove_delete_nested_key() {
    # Set up nested key
    D config --scope=user set nested.config.key "nested_value" > /dev/null
    
    # Delete a nested key
    D config --scope=user remove nested.config.key > /dev/null
    
    # Verify the key was deleted
    local key_exists
    key_exists=$(D config --scope=user get nested.config.key 2>/dev/null || echo "not_found")
    assert_equals "not_found" "$key_exists" "Nested key should be deleted"
    
    # Verify parent objects remain
    local json_content
    json_content=$(D config --scope=user print)
    assert_contains "$json_content" "nested" "Parent object should still exist"
}

# Test deleting a parent key removes all children
test_config_remove_delete_parent_key() {
    # First ensure the nested structure exists
    D config --scope=user set parent.child1.key "value1" > /dev/null
    D config --scope=user set parent.child2.key "value2" > /dev/null
    
    # Delete the parent key
    D config --scope=user remove parent > /dev/null
    
    # Verify all children are deleted
    local child1_exists child2_exists parent_exists
    child1_exists=$(D config --scope=user get parent.child1.key 2>/dev/null || echo "not_found")
    child2_exists=$(D config --scope=user get parent.child2.key 2>/dev/null || echo "not_found")
    parent_exists=$(D config --scope=user get parent 2>/dev/null || echo "not_found")
    
    assert_equals "not_found" "$child1_exists" "Child1 key should be deleted"
    assert_equals "not_found" "$child2_exists" "Child2 key should be deleted"
    assert_equals "not_found" "$parent_exists" "Parent key should be deleted"
}

# Test deleting an array entirely
test_config_remove_delete_array() {
    # Set up an array
    D config --scope=user set array.test 'item1,item2' > /dev/null
    
    # Delete the entire array
    D config --scope=user remove array.test > /dev/null
    
    # Verify the array was deleted
    local array_exists
    array_exists=$(D config --scope=user get array.test 2>/dev/null || echo "not_found")
    assert_equals "not_found" "$array_exists" "Array should be deleted"
}

# Test deleting keys in different scopes
test_config_remove_delete_different_scopes() {
    # Set up keys in different scopes
    D config --scope=user set scope.test "user_value" > /dev/null
    D config --scope=repository set scope.test "repo_value" > /dev/null
    D config --scope=context set scope.test "context_value" > /dev/null
    
    # Delete keys in different scopes
    D config --scope=user remove scope.test > /dev/null
    D config --scope=repository remove scope.test > /dev/null
    D config --scope=context remove scope.test > /dev/null
    
    # Verify keys were deleted from the correct scopes
    local user_value repo_value context_value
    user_value=$(D config --scope=user get scope.test 2>/dev/null || echo "not_found")
    repo_value=$(D config --scope=repository get scope.test 2>/dev/null || echo "not_found")
    context_value=$(D config --scope=context get scope.test 2>/dev/null || echo "not_found")
    
    assert_equals "not_found" "$user_value" "Key should be deleted from user scope"
    assert_equals "not_found" "$repo_value" "Key should be deleted from repository scope"
    assert_equals "not_found" "$context_value" "Key should be deleted from context scope"
}

# Test deleting a non-existent key
test_config_remove_delete_nonexistent_key() {
    # Try to remove a non-existent key
    local result
    result=$(D config --scope=user remove nonexistent.key 2>&1)
    
    # Verify behavior for non-existent keys
    # At minimum, ensure it doesn't crash
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user remove nonexistent.key" "Removing non-existent key should not fail"
}
