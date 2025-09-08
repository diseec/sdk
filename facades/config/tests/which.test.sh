#!/bin/bash

# Test for the 'config which' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "config_which_tests")
    
    # Initialize config
    cd "$TEST_WORKSPACE" && D config init > /dev/null
    
    # Set up some test configurations in different scopes
    cd "$TEST_WORKSPACE" && D config --scope=user set test.key "user_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository set test.key "repo_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context set test.key "context_value" > /dev/null
    
    # Set up unique keys in each scope
    cd "$TEST_WORKSPACE" && D config --scope=user set user.only "user_only_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=repository set repo.only "repo_only_value" > /dev/null
    cd "$TEST_WORKSPACE" && D config --scope=context set context.only "context_only_value" > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test which shows config resolution path for shared key
test_config_which_shared_key() {
    # Get which info for test.key
    local which_output
    which_output=$(cd "$TEST_WORKSPACE" && D config which test.key)
    
    # Verify output contains all scopes with the key
    assert_contains "$which_output" "context" "Which output should mention context scope"
    assert_contains "$which_output" "repository" "Which output should mention repository scope"
    assert_contains "$which_output" "user" "Which output should mention user scope"
    
    # Verify it shows the hierarchy
    # This may depend on exact output format, so adapt as needed
    assert_matches "$which_output" ".*context.*repository.*user.*" "Which output should show hierarchy"
}

# Test which shows resolution for user-only key
test_config_which_user_only_key() {
    # Get which info for user.only
    local which_output
    which_output=$(cd "$TEST_WORKSPACE" && D config which user.only)
    
    # Verify output mentions user scope but not others
    assert_contains "$which_output" "user" "Which output should mention user scope"
    assert_not_contains "$which_output" "context.*user.only" "Which output should not show key in context scope"
    assert_not_contains "$which_output" "repository.*user.only" "Which output should not show key in repository scope"
}

# Test which shows resolution for repo-only key
test_config_which_repo_only_key() {
    # Get which info for repo.only
    local which_output
    which_output=$(cd "$TEST_WORKSPACE" && D config which repo.only)
    
    # Verify output mentions repository scope but not others
    assert_contains "$which_output" "repository" "Which output should mention repository scope"
    assert_not_contains "$which_output" "context.*repo.only" "Which output should not show key in context scope"
    assert_not_contains "$which_output" "user.*repo.only" "Which output should not show key in user scope"
}

# Test which shows resolution for context-only key
test_config_which_context_only_key() {
    # Get which info for context.only
    local which_output
    which_output=$(cd "$TEST_WORKSPACE" && D config which context.only)
    
    # Verify output mentions context scope but not others
    assert_contains "$which_output" "context" "Which output should mention context scope"
    assert_not_contains "$which_output" "repository.*context.only" "Which output should not show key in repository scope"
    assert_not_contains "$which_output" "user.*context.only" "Which output should not show key in user scope"
}

# Test which for non-existent key
test_config_which_nonexistent_key() {
    # Get which info for a non-existent key
    local which_output
    which_output=$(cd "$TEST_WORKSPACE" && D config which nonexistent.key)
    
    # Verify output indicates key not found in any scope
    assert_contains "$which_output" "not found" "Which output should indicate key not found"
}
