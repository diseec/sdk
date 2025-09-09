#!/bin/bash

# Test for the 'ai generate' commands

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Create a test workspace
    export TEST_WORKSPACE
    TEST_WORKSPACE=$(create_test_workspace "ai_generate_tests")
    
    # Store original OPENAI_API_KEY for restoration
    export ORIGINAL_OPENAI_API_KEY="$OPENAI_API_KEY"
    
    # Initialize a git repository for testing
    cd "$TEST_WORKSPACE" && git init > /dev/null 2>&1
    cd "$TEST_WORKSPACE" && git config user.email "test@example.com" > /dev/null 2>&1
    cd "$TEST_WORKSPACE" && git config user.name "Test User" > /dev/null 2>&1
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
    
    # Restore original API key
    export OPENAI_API_KEY="$ORIGINAL_OPENAI_API_KEY"
}

# Test generate commit without staged changes
test_ai_generate_commit_no_changes() {
    # Clear any potential staged changes
    cd "$TEST_WORKSPACE" && git reset > /dev/null 2>&1
    
    local output
    output=$(d ai generate commit 2>&1)
    result=$?
    
    # Should fail when no staged changes
    assert_not_equals "0" "$result" "Should fail when no staged changes"
    
    # Should indicate no staged changes
    assert_contains "$output" "No staged changes\|stage your changes" "Should indicate no staged changes"
}

# Test generate commit with staged changes but no API key
test_ai_generate_commit_no_api_key() {
    # Clear API key
    unset OPENAI_API_KEY
    
    # Create and stage a test file
    echo "test content" > "$TEST_WORKSPACE/test.txt"
    cd "$TEST_WORKSPACE" && git add test.txt
    
    local output
    output=$(d ai generate commit 2>&1)
    result=$?
    
    # Should fail when AI services not available
    assert_not_equals "0" "$result" "Should fail when AI services not available"
    
    # Should indicate AI not available
    assert_contains "$output" "AI services not available\|not available" "Should indicate AI not available"
}

# Test generate commit help
test_ai_generate_commit_help() {
    local output
    output=$(d ai help generate 2>&1)
    
    # Should succeed
    assert_equals "0" "$?" "Generate help should succeed"
    
    # Should contain commit option
    assert_contains "$output" "commit" "Help should mention commit command"
}

# Test generate insight without input
test_ai_generate_insight_no_input() {
    # Clear API key to avoid actual API calls
    unset OPENAI_API_KEY
    
    local output
    output=$(d ai generate insight 2>&1)
    result=$?
    
    # Should fail when AI services not available
    assert_not_equals "0" "$result" "Should fail when AI services not available"
    
    # Should indicate AI not available
    assert_contains "$output" "AI services not available\|not available" "Should indicate AI not available"
}

# Test generate prompt with non-existent prompt
test_ai_generate_prompt_nonexistent() {
    # Set dummy API key to pass availability check
    export OPENAI_API_KEY="sk-test123"
    
    local output
    output=$(d ai generate prompt nonexistent-prompt 2>&1)
    result=$?
    
    # Should fail
    assert_not_equals "0" "$result" "Should fail with non-existent prompt"
    
    # Should indicate prompt not found
    assert_contains "$output" "not found" "Should indicate prompt not found"
}

# Test generate prompt without prompt name
test_ai_generate_prompt_missing_name() {
    local output
    output=$(d ai generate prompt 2>&1)
    result=$?
    
    # Should fail
    assert_not_equals "0" "$result" "Should fail without prompt name"
    
    # Should indicate prompt name required
    assert_contains "$output" "required\|Usage" "Should indicate prompt name required or show usage"
}

# Test generate command structure
test_ai_generate_command_structure() {
    # Test invalid subcommand
    local output
    output=$(d ai generate invalid-command 2>&1)
    result=$?
    
    # Should fail
    assert_not_equals "0" "$result" "Should fail with invalid subcommand"
    
    # Should indicate unknown command
    assert_contains "$output" "Unknown\|help" "Should indicate unknown command or show help"
}
