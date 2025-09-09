#!/bin/bash

# Test for the 'config path' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_path_tests")
    
    # Initialize config
    d config init > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test getting path for each scope
test_config_path_each_scope() {
    # Get paths for each scope
    local user_path repo_path context_path
    user_path=$(d config --scope=user path)
    repo_path=$(d config --scope=repository path)
    context_path=$(d config --scope=context path)
    
    # Verify each path is returned and not empty
    assert_not_empty "$user_path" "User config path should not be empty"
    assert_not_empty "$repo_path" "Repository config path should not be empty"
    assert_not_empty "$context_path" "Context config path should not be empty"
    
    # Verify the paths point to files that exist
    assert_file_exists "$user_path" "User config file should exist"
    assert_file_exists "$repo_path" "Repository config file should exist"
    assert_file_exists "$context_path" "Context config file should exist"
}

# Test that paths are unique
test_config_path_uniqueness() {
    # Get paths for each scope
    local user_path repo_path context_path
    user_path=$(d config --scope=user path)
    repo_path=$(d config --scope=repository path)
    context_path=$(d config --scope=context path)
    
    # Verify paths are different
    assert_not_equals "$user_path" "$repo_path" "User and repository paths should be different"
    assert_not_equals "$user_path" "$context_path" "User and context paths should be different"
    assert_not_equals "$repo_path" "$context_path" "Repository and context paths should be different"
}

# Test that returned paths are absolute
test_config_path_absolute() {
    # Get paths for each scope
    local user_path repo_path context_path
    user_path=$(d config --scope=user path)
    repo_path=$(d config --scope=repository path)
    context_path=$(d config --scope=context path)
    
    # Verify paths are absolute (start with /)
    assert_matches "$user_path" "^/" "User config path should be absolute"
    assert_matches "$repo_path" "^/" "Repository config path should be absolute"
    assert_matches "$context_path" "^/" "Context config path should be absolute"
}
