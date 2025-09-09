#!/bin/bash

# Test for the 'config summary' command

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Initialize config
    d config init > /dev/null
    
    # Set up some test configurations in different scopes
    d config --scope=user set user.key "user_value" > /dev/null
    d config --scope=repository set repo.key "repo_value" > /dev/null
    d config --scope=context set context.key "context_value" > /dev/null
}


# Test summary shows all scopes
test_config_summary_shows_all_scopes() {
    # Get summary
    local summary_output
    summary_output=$(d config summary)
    
    # Verify it mentions all scopes (case-insensitive)
    assert_contains "$summary_output" "USER" "Summary should mention user scope"
    assert_contains "$summary_output" "REPOSITORY" "Summary should mention repository scope"  
    assert_contains "$summary_output" "CONTEXT" "Summary should mention context scope"
}

# Test summary shows config file paths
test_config_summary_shows_paths() {
    # Get summary
    local summary_output
    summary_output=$(d config summary)
    
    # Get the config paths to compare
    local user_path repo_path context_path
    user_path=$(d config --scope=user path)
    repo_path=$(d config --scope=repository path)
    context_path=$(d config --scope=context path)
    
    # Verify paths are mentioned in the summary
    # This may depend on how paths are formatted in the summary
    assert_contains "$summary_output" "$user_path" "Summary should show user config path"
    assert_contains "$summary_output" "$repo_path" "Summary should show repository config path"
    assert_contains "$summary_output" "$context_path" "Summary should show context config path"
}

# Test summary shows key counts
test_config_summary_shows_key_counts() {
    # Get summary
    local summary_output
    summary_output=$(d config summary)
    
    # Verify it mentions the number of keys
    # This may depend on how the counts are formatted
    assert_contains "$summary_output" "1" "Summary should show key counts"
}

# Test summary with no configs
test_config_summary_with_no_configs() {
    # Create a new empty workspace
    local empty_workspace
    empty_workspace=$(create_test_workspace "empty_config_test")
    
    # Get summary before initializing configs
    local summary_output
    summary_output=$(cd "$empty_workspace" && D config summary)
    
    # Verify it handles the case with no configs
    assert_not_empty "$summary_output" "Summary should provide output even with no configs"
    
    # Clean up
    cleanup_test_workspace "$empty_workspace"
}
