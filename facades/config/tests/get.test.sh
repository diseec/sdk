#!/bin/bash

# Test for the 'config get' command

# Suite setup - runs once before all tests in this file
setup_test() {
    # Set up some test configurations in different scopes
    D config --scope=user set test.key "user_value" > /dev/null
    D config --scope=repository set test.key "repo_value" > /dev/null
    D config --scope=context set test.key "context_value" > /dev/null
    
    # Add some nested configurations
    D config --scope=user set nested.config.key "nested_value" > /dev/null
    
    # Add some arrays
    D config --scope=user set array.test 'item1,item2' > /dev/null
}


# Test basic get functionality with scope
test_config_get_with_scope() {
    # Set up fresh values for this test (in case other tests modified them)
    D config --scope=user set test.key "user_value" > /dev/null
    D config --scope=repository set test.key "repo_value" > /dev/null
    D config --scope=context set test.key "context_value" > /dev/null
    
    # Get value from user scope
    local user_value
    user_value=$(D config --scope=user get test.key)
    assert_equals "user_value" "$user_value" "Should get correct value from user scope"
    
    # Get value from repository scope
    local repo_value
    repo_value=$(D config --scope=repository get test.key)
    assert_equals "repo_value" "$repo_value" "Should get correct value from repository scope"
    
    # Get value from context scope
    local context_value
    context_value=$(D config --scope=context get test.key)
    assert_equals "context_value" "$context_value" "Should get correct value from context scope"
}

# Test getting nested configuration values
test_config_get_nested_values() {
    local nested_value
    nested_value=$(D config --scope=user get nested.config.key)
    assert_equals "nested_value" "$nested_value" "Should get nested configuration values"
}

# Test getting non-existent keys
test_config_get_nonexistent_key() {
    # Try to get a non-existent key
    local result
    result=$(D config --scope=user get nonexistent.key)
    
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
    resolved_value=$(D config get test.key)
    assert_equals "context_value" "$resolved_value" "Hierarchy resolution should return context value"
    
    # If we delete from context, it should fall back to repository
    D config --scope=context remove test.key > /dev/null
    resolved_value=$(D config get test.key)
    assert_equals "repo_value" "$resolved_value" "Hierarchy resolution should fall back to repository"
    
    # If we delete from repository, it should fall back to user
    D config --scope=repository remove test.key > /dev/null
    resolved_value=$(D config get test.key)
    assert_equals "user_value" "$resolved_value" "Hierarchy resolution should fall back to user"
}
