#!/bin/bash

# Test for the 'config init' command

# Test init command creates configuration files
test_config_init_creates_files() {
    # Run the init command
    local output
    output=$(D config init)
    
    # Check that the command succeeds
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config init" "Config init should succeed"
    
    # Verify the output contains a success message
    assert_contains "$output" "initialized" "Output should indicate initialization"
    
    # Get the config file paths
    local context_file
    context_file=$(D config --scope=context path)
    local repo_file
    repo_file=$(D config --scope=repository path)
    local user_file
    user_file=$(D config --scope=user path)
    
    # Verify that config files exist
    assert_file_exists "$context_file" "Context config file should exist"
    assert_file_exists "$repo_file" "Repository config file should exist"
    assert_file_exists "$user_file" "User config file should exist"
}

# Test init doesn't overwrite existing files
test_config_init_preserves_existing() {
    # First get the config file paths
    local context_file
    context_file=$(D config --scope=context path)
    
    # Add some custom content to the context file
    echo '{"test": "custom_value"}' > "$context_file"
    
    # Run init again
    local output
    output=$(D config init)
    
    # Check the file still has our custom content
    local file_content
    file_content=$(cat "$context_file")
    assert_contains "$file_content" "custom_value" "Init should preserve existing configuration"
}
