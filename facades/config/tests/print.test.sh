#!/bin/bash

# Test for the 'config print' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_print_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
    
    # Set up some test configurations in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user set user.key "user_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user set shared.key "user_shared" > /dev/null
    
    cd "$TEST_WORKSPACE" && D config --scope=repository set repo.key "repo_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository set shared.key "repo_shared" > /dev/null
    
    cd "$TEST_WORKSPACE" && D config --scope=context set context.key "context_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context set shared.key "context_shared" > /dev/null
    
    # Set up nested configurations
    cd "$TEST_WORKSPACE" && D config --scope=user set nested.config.key "nested_value" > /dev/null
    
    # Set up arrays
    cd "$TEST_WORKSPACE" && D config --scope=user set array.test '["item1", "item2", "item3"]' > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test printing a specific scope
test_config_print_specific_scope() {
    # Print user scope
    local user_output
    user_output=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    
    # Verify output contains user-specific keys
    assert_contains "$user_output" "user.key" "Output should contain user.key"
    assert_contains "$user_output" "user_value" "Output should contain user_value"
    
    # Verify it also contains shared keys in this scope
    assert_contains "$user_output" "shared.key" "Output should contain shared.key"
    assert_contains "$user_output" "user_shared" "Output should contain user_shared"
    
    # Verify it doesn't contain keys from other scopes
    assert_not_contains "$user_output" "repo.key" "Output should not contain repo.key"
    assert_not_contains "$user_output" "context.key" "Output should not contain context.key"
}

# Test printing all scopes (when no scope is specified)
test_config_print_all_scopes() {
    # Print all scopes
    local all_output
    all_output=$(cd "$TEST_WORKSPACE" && D config print)
    
    # Verify output contains keys from all scopes
    assert_contains "$all_output" "user.key" "Output should contain user.key"
    assert_contains "$all_output" "repo.key" "Output should contain repo.key"
    assert_contains "$all_output" "context.key" "Output should contain context.key"
    
    # Verify it contains the shared key values from each scope
    assert_contains "$all_output" "user_shared" "Output should contain user_shared"
    assert_contains "$all_output" "repo_shared" "Output should contain repo_shared"
    assert_contains "$all_output" "context_shared" "Output should contain context_shared"
}

# Test that print output is valid JSON
test_config_print_valid_json() {
    # Print user scope
    local user_output
    user_output=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    
    # Validate JSON by trying to parse it with jq
    # Note: This assumes jq is available on the system
    assert_command_success "echo '$user_output' | jq ." "Print output should be valid JSON"
}

# Test that print includes nested configurations
test_config_print_nested_configs() {
    # Print user scope
    local user_output
    user_output=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    
    # Verify output contains nested configuration
    assert_contains "$user_output" "nested" "Output should contain nested object"
    assert_contains "$user_output" "config" "Output should contain config object"
    assert_contains "$user_output" "nested_value" "Output should contain nested_value"
}

# Test that print includes arrays
test_config_print_arrays() {
    # Print user scope
    local user_output
    user_output=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    
    # Verify output contains array
    assert_contains "$user_output" "array" "Output should contain array object"
    assert_contains "$user_output" "item1" "Output should contain item1"
    assert_contains "$user_output" "item2" "Output should contain item2"
    assert_contains "$user_output" "item3" "Output should contain item3"
}
