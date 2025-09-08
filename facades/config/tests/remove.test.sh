#!/bin/bash

# Test for the 'config remove' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_remove_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
    
    # Set up some test arrays
    cd "$TEST_WORKSPACE" && D config --scope=user set simple.array '["item1", "item2", "item3"]' > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add nested.array "item1" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add nested.array "item2" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add nested.array "item3" > /dev/null
    
    # Set up arrays in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user add scope.array "user_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository add scope.array "repo_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context add scope.array "context_item" > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test removing an item from an array
test_config_remove_item() {
    # Remove an item from the array
    local output
    output=$(cd "$TEST_WORKSPACE" && D config --scope=user remove simple.array "item2")
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user remove simple.array \"item2\"" "Remove command should succeed"
    
    # Verify the item was removed
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get simple.array)
    assert_contains "$array_value" "item1" "Array should still contain first item"
    assert_not_contains "$array_value" "item2" "Array should not contain removed item"
    assert_contains "$array_value" "item3" "Array should still contain third item"
}

# Test removing the last item from an array
test_config_remove_last_item() {
    # Create a single-item array
    cd "$TEST_WORKSPACE" && D config --scope=user set single.array '["only_item"]' > /dev/null
    
    # Remove the only item
    cd "$TEST_WORKSPACE" && D config --scope=user remove single.array "only_item" > /dev/null
    
    # Verify what happens when the last item is removed
    # This test might need adjustment based on the actual implementation
    # Some systems might keep an empty array, others might remove the key entirely
    
    local array_exists
    array_exists=$(cd "$TEST_WORKSPACE" && D config --scope=user get single.array 2>/dev/null || echo "not_found")
    
    # Adjust this assertion based on expected behavior
    # Here we're assuming an empty array is kept
    assert_not_equals "not_found" "$array_exists" "Array should still exist even when empty"
    assert_matches "$array_exists" "\\[\\s*\\]" "Array should be empty after removing the last item"
}

# Test removing a non-existent item
test_config_remove_nonexistent_item() {
    # Try to remove an item that doesn't exist
    local result
    result=$(cd "$TEST_WORKSPACE" && D config --scope=user remove simple.array "nonexistent_item" 2>&1)
    
    # Verify behavior for non-existent items
    # This might be implementation-dependent
    # Some systems might fail, others might just ignore it
    
    # Check that the array remains unchanged
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get simple.array)
    assert_contains "$array_value" "item1" "Array should remain unchanged"
    assert_contains "$array_value" "item3" "Array should remain unchanged"
}

# Test removing from arrays in different scopes
test_config_remove_different_scopes() {
    # Remove items from arrays in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user remove scope.array "user_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository remove scope.array "repo_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context remove scope.array "context_item" > /dev/null
    
    # Verify items were removed from the correct arrays
    local user_array repo_array context_array
    user_array=$(cd "$TEST_WORKSPACE" && D config --scope=user get scope.array 2>/dev/null || echo "not_found")
    repo_array=$(cd "$TEST_WORKSPACE" && D config --scope=repository get scope.array 2>/dev/null || echo "not_found")
    context_array=$(cd "$TEST_WORKSPACE" && D config --scope=context get scope.array 2>/dev/null || echo "not_found")
    
    # Check each array is now empty or removed
    assert_not_contains "$user_array" "user_item" "User scope array should not contain removed item"
    assert_not_contains "$repo_array" "repo_item" "Repository scope array should not contain removed item"
    assert_not_contains "$context_array" "context_item" "Context scope array should not contain removed item"
}

# Test removing an item from a nested array
test_config_remove_nested_array() {
    # Remove an item from a nested array
    cd "$TEST_WORKSPACE" && D config --scope=user remove nested.array "item2" > /dev/null
    
    # Verify it was removed correctly
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get nested.array)
    assert_contains "$array_value" "item1" "Nested array should still contain first item"
    assert_not_contains "$array_value" "item2" "Nested array should not contain removed item"
    assert_contains "$array_value" "item3" "Nested array should still contain third item"
}
