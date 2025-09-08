#!/bin/bash

# Test for the 'config add' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_add_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test adding to a new array
test_config_add_new_array() {
    # Add an item to a new array
    local output
    output=$(cd "$TEST_WORKSPACE" && D config --scope=user add new.array "item1")
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config --scope=user add new.array \"item1\"" "Add command should succeed"
    
    # Verify the array was created and contains the item
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get new.array)
    assert_contains "$array_value" "item1" "Array should contain the added item"
}

# Test adding multiple items to an array
test_config_add_multiple_items() {
    # Add multiple items to an array
    cd "$TEST_WORKSPACE" && D config --scope=user add multiple.array "item1" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add multiple.array "item2" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add multiple.array "item3" > /dev/null
    
    # Verify all items were added
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get multiple.array)
    assert_contains "$array_value" "item1" "Array should contain first item"
    assert_contains "$array_value" "item2" "Array should contain second item"
    assert_contains "$array_value" "item3" "Array should contain third item"
    
    # Verify order using print command
    local json_content
    json_content=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    
    # The order check might be implementation-dependent
    # We're assuming the JSON representation will show the array in order
    assert_matches "$json_content" ".*\"item1\".*\"item2\".*\"item3\".*" "Items should be in the order they were added"
}

# Test adding duplicate items
test_config_add_duplicate_items() {
    # Add an item twice
    cd "$TEST_WORKSPACE" && D config --scope=user add duplicate.array "item1" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=user add duplicate.array "item1" > /dev/null
    
    # Verify how the system handles duplicates
    # This test might need adjustment based on the actual implementation
    # Some systems might allow duplicates, others might prevent them
    
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get duplicate.array)
    
    # Count occurrences of "item1" in the array
    local count
    count=$(echo "$array_value" | grep -o "item1" | wc -l)
    
    # Adjust this assertion based on expected behavior
    # Here we're assuming duplicates are prevented
    assert_equals "1" "$count" "Duplicate items should be handled properly"
}

# Test adding to arrays in different scopes
test_config_add_different_scopes() {
    # Add items to arrays in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user add scope.array "user_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository add scope.array "repo_item" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context add scope.array "context_item" > /dev/null
    
    # Verify items were added to the correct arrays
    local user_array repo_array context_array
    user_array=$(cd "$TEST_WORKSPACE" && D config --scope=user get scope.array)
    repo_array=$(cd "$TEST_WORKSPACE" && D config --scope=repository get scope.array)
    context_array=$(cd "$TEST_WORKSPACE" && D config --scope=context get scope.array)
    
    assert_contains "$user_array" "user_item" "User scope array should contain user item"
    assert_contains "$repo_array" "repo_item" "Repository scope array should contain repo item"
    assert_contains "$context_array" "context_item" "Context scope array should contain context item"
}

# Test adding to a nested array
test_config_add_nested_array() {
    # Add an item to a nested array
    cd "$TEST_WORKSPACE" && D config --scope=user add nested.config.array "nested_item" > /dev/null
    
    # Verify it was added correctly
    local array_value
    array_value=$(cd "$TEST_WORKSPACE" && D config --scope=user get nested.config.array)
    assert_contains "$array_value" "nested_item" "Nested array should contain the added item"
    
    # Verify the structure was created correctly
    local json_content
    json_content=$(cd "$TEST_WORKSPACE" && D config --scope=user print)
    assert_contains "$json_content" "nested" "JSON should contain the nested object"
    assert_contains "$json_content" "config" "JSON should contain the config object"
}
