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
