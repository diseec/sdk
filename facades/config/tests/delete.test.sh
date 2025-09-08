#!/bin/bash

# Test for the 'config delete' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_delete_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
    
    # Set up some test configurations
    cd "$TEST_WORKSPACE" && D config --scope=user set simple.key "simple_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user set nested.config.key "nested_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user set array.test '["item1", "item2"]' > /dev/null
    
    # Set up configs in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user set scope.test "user_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository set scope.test "repo_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context set scope.test "context_value" > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test deleting a simple key
test_config_delete_simple_key() {
    # Delete a simple key
    local output
    output=$(cd "$TEST_WORKSPACE" && D config --scope=user delete simple.key)
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user delete simple.key" "Delete command should succeed"
    
    # Verify the key was deleted
    local key_exists
    key_exists=$(cd "$TEST_WORKSPACE" && D config --scope=user get simple.key 2>/dev/null || echo "not_found")
    assert_equals "not_found" "$key_exists" "Key should be deleted"
}

# Test deleting a nested key
test_config_delete_nested_key() {
    # Delete a nested key
    cd "$TEST_WORKSPACE" && D config --scope=user delete nested.config.key > /dev/null
    
    # Verify the key was deleted
    local key_exists
    key_exists=$(cd "$TEST_WORKSPACE" && D config --scope=user get nested.config.key 2>/dev/null || echo "not_found")
    assert_equals "not_found" "$key_exists" "Nested key should be deleted"
    
    # Verify parent objects remain
    local json_content
    json_content=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    assert_contains "$json_content" "nested" "Parent object should still exist"
}

# Test deleting a parent key removes all children
test_config_delete_parent_key() {
    # First ensure the nested structure exists
    cd "$TEST_WORKSPACE" && D config --scope=user set parent.child1.key "value1" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user set parent.child2.key "value2" > /dev/null
    
    # Delete the parent key
    cd "$TEST_WORKSPACE" && D config --scope=user delete parent > /dev/null
    
    # Verify all children are deleted
    local child1_exists child2_exists parent_exists
    child1_exists=$(cd "$TEST_WORKSPACE" && D config --scope=user get parent.child1.key 2>/dev/null || echo "not_found")
    child2_exists=$(cd "$TEST_WORKSPACE" && D config --scope=user get parent.child2.key 2>/dev/null || echo "not_found")
    parent_exists=$(cd "$TEST_WORKSPACE" && D config --scope=user get parent 2>/dev/null || echo "not_found")
    
    assert_equals "not_found" "$child1_exists" "Child1 key should be deleted"
    assert_equals "not_found" "$child2_exists" "Child2 key should be deleted"
    assert_equals "not_found" "$parent_exists" "Parent key should be deleted"
}

# Test deleting an array
test_config_delete_array() {
    # Delete an array
    cd "$TEST_WORKSPACE" && D config --scope=user delete array.test > /dev/null
    
    # Verify the array was deleted
    local array_exists
    array_exists=$(cd "$TEST_WORKSPACE" && D config --scope=user get array.test 2>/dev/null || echo "not_found")
    assert_equals "not_found" "$array_exists" "Array should be deleted"
}

# Test deleting in different scopes
test_config_delete_different_scopes() {
    # Delete keys in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user delete scope.test > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository delete scope.test > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context delete scope.test > /dev/null
    
    # Verify keys were deleted from the correct scopes
    local user_value repo_value context_value
    user_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get scope.test 2>/dev/null || echo "not_found")
    repo_value=$(cd "$TEST_WORKSPACE" && D config --scope=repository get scope.test 2>/dev/null || echo "not_found")
    context_value=$(cd "$TEST_WORKSPACE" && D config --scope=context get scope.test 2>/dev/null || echo "not_found")
    
    assert_equals "not_found" "$user_value" "Key should be deleted from user scope"
    assert_equals "not_found" "$repo_value" "Key should be deleted from repository scope"
    assert_equals "not_found" "$context_value" "Key should be deleted from context scope"
}

# Test deleting a non-existent key
test_config_delete_nonexistent_key() {
    # Try to delete a non-existent key
    local result
    result=$(cd "$TEST_WORKSPACE" && D config --scope=user delete nonexistent.key 2>&1)
    
    # Verify behavior for non-existent keys
    # This might be implementation-dependent
    # Some systems might fail, others might just ignore it
    
    # At minimum, ensure it doesn't crash
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user delete nonexistent.key" "Deleting non-existent key should not fail"
}
