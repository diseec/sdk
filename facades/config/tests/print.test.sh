#!/bin/bash

# Test for the 'config print' command

# Suite setup - runs once before all tests in this file
setup_test() {
    # Set up some test configurations in different scopes
    D config --scope=user set user.key "user_value"
    D config --scope=user set shared.key "user_shared"
    
    D config --scope=repository set repo.key "repo_value"
    D config --scope=repository set shared.key "repo_shared"
    
    D config --scope=context set context.key "context_value"
    D config --scope=context set shared.key "context_shared"
    
    # Set up nested configurations
    D config --scope=user set nested.config.key "nested_value"
    
    # Set up arrays
    D config --scope=user set array.test 'item1,item2,item3'
}

# Test printing a specific scope
test_config_print_specific_scope() {
    # Print user scope
    local user_output
    user_output=$(D config --scope=user print)
    
    # Verify output contains user-specific keys
    assert_contains "$user_output" "user:" "Output should contain user section"
    assert_contains "$user_output" "user_value" "Output should contain user_value"
    
    # Verify it also contains shared keys in this scope
    assert_contains "$user_output" "shared:" "Output should contain shared section"
    assert_contains "$user_output" "user_shared" "Output should contain user_shared"
    
    # Verify it doesn't contain keys from other scopes
    assert_not_contains "$user_output" "repo:" "Output should not contain repo section"
    assert_not_contains "$user_output" "context:" "Output should not contain context section"
}

# Test printing all scopes (when no scope is specified)
test_config_print_all_scopes() {
    # Print all scopes
    local all_output
    all_output=$(D config print)
    
    # Verify output contains keys from all scopes
    assert_contains "$all_output" "user:" "Output should contain user section"
    assert_contains "$all_output" "repo:" "Output should contain repo section"  
    assert_contains "$all_output" "context:" "Output should contain context section"
    
    # Verify it contains the shared key values from each scope
    assert_contains "$all_output" "user_shared" "Output should contain user_shared"
    assert_contains "$all_output" "repo_shared" "Output should contain repo_shared"
    assert_contains "$all_output" "context_shared" "Output should contain context_shared"
}

# Test that print output is valid YAML
test_config_print_valid_yaml() {
    # Print user scope
    local user_output
    user_output=$(D config --scope=user print)
    
    # Extract just the YAML content (skip the header lines)
    local yaml_content
    yaml_content=$(echo "$user_output" | tail -n +4)  # Skip first 3 lines (header info)
    
    # Validate YAML by trying to parse it with yq
    assert_command_success "echo '$yaml_content' | yq eval ." "Print output should be valid YAML"
}

# Test that print includes nested configurations
test_config_print_nested_configs() {
    # Print user scope
    local user_output
    user_output=$(D config --scope=user print)
    
    # Verify output contains nested configuration
    assert_contains "$user_output" "nested" "Output should contain nested object"
    assert_contains "$user_output" "config" "Output should contain config object"
    assert_contains "$user_output" "nested_value" "Output should contain nested_value"
}

# Test that print includes arrays
test_config_print_arrays() {
    # Print user scope
    local user_output
    user_output=$(D config --scope=user print)
    
    # Verify output contains array
    assert_contains "$user_output" "array" "Output should contain array object"
    assert_contains "$user_output" "item1" "Output should contain item1"
    assert_contains "$user_output" "item2" "Output should contain item2"
    assert_contains "$user_output" "item3" "Output should contain item3"
}
