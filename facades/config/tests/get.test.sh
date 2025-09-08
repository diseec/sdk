#!/bin/bash

# Test for the 'config get' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_get_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
    
    # Set up some test configurations in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user set test.key "user_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository set test.key "repo_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context set test.key "context_value" > /dev/null
    
    # Add some nested configurations
    cd "$TEST_WORKSPACE" && D config --scope=user set nested.config.key "nested_value" > /dev/null
    
    # Add some arrays
    cd "$TEST_WORKSPACE" && D config --scope=user set array.test '["item1", "item2"]' > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test basic get functionality with scope
test_config_get_with_scope() {
    # Get value from user scope
    local user_value
    user_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get test.key)
    assert_equals "user_value" "$user_value" "Should get correct value from user scope"
    
    # Get value from repository scope
    local repo_value
    repo_value=$(cd "$TEST_WORKSPACE" && D config --scope=repository get test.key)
    assert_equals "repo_value" "$repo_value" "Should get correct value from repository scope"
    
    # Get value from context scope
    local context_value
    context_value=$(cd "$TEST_WORKSPACE" && D config --scope=context get test.key)
    assert_equals "context_value" "$context_value" "Should get correct value from context scope"
}

# Test getting nested configuration values
test_config_get_nested_values() {
    local nested_value
    nested_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get nested.config.key)
    assert_equals "nested_value" "$nested_value" "Should get nested configuration values"
}

# Test getting non-existent keys
test_config_get_nonexistent_key() {
    # Try to get a non-existent key
    local result
    result=$(cd "$TEST_WORKSPACE" && D config --scope=user get nonexistent.key 2>&1)
    
    # Check that the command indicates key not found
    assert_not_equals "0" "$?" "Command should indicate failure for non-existent key"
    assert_contains "$result" "not found" "Output should indicate key not found"
}

# Test hierarchy resolution (without specifying scope)
test_config_get_hierarchy_resolution() {
    # When no scope is specified, config should resolve based on hierarchy
    # Context > Repository > User
    
    # Since we set the same key in all scopes, it should return the highest priority
    local resolved_value
    resolved_value=$(cd "$TEST_WORKSPACE" && D config get test.key)
    assert_equals "context_value" "$resolved_value" "Hierarchy resolution should return context value"
    
    # If we delete from context, it should fall back to repository
    cd "$TEST_WORKSPACE" && D config --scope=context delete test.key > /dev/null
    resolved_value=$(cd "$TEST_WORKSPACE" && D config get test.key)
    assert_equals "repo_value" "$resolved_value" "Hierarchy resolution should fall back to repository"
    
    # If we delete from repository, it should fall back to user
    cd "$TEST_WORKSPACE" && D config --scope=repository delete test.key > /dev/null
    resolved_value=$(cd "$TEST_WORKSPACE" && D config get test.key)
    assert_equals "user_value" "$resolved_value" "Hierarchy resolution should fall back to user"
}
