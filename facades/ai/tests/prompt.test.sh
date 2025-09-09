#!/bin/bash

# Test for the 'ai prompt' commands

# Suite setup - runs once before all tests in this file
suite_setup() {
    
    # Create a test prompt file for testing
    export TEST_PROMPT_FILE="$TEST_WORKSPACE/test.prompt"
    echo "# Test prompt for demonstration" > "$TEST_PROMPT_FILE"
    echo "This is a test prompt with {{INPUT}} placeholder." >> "$TEST_PROMPT_FILE"
}

# Test prompt list command
test_ai_prompt_list() {
    local output
    output=$(d ai prompt list 2>&1)
    
    # Command should succeed
    assert_equals "0" "$?" "Prompt list command should succeed"
    
    # Output should contain header
    assert_contains "$output" "Available AI Prompts" "Should show prompts header"
}

# Test prompt list with verbose flag
test_ai_prompt_list_verbose() {
    local output
    output=$(d ai prompt list --verbose 2>&1)
    
    # Command should succeed
    assert_equals "0" "$?" "Prompt list --verbose should succeed"
    
    # Should contain header
    assert_contains "$output" "Available AI Prompts" "Verbose list should show header"
}

# Test prompt show for built-in prompts
test_ai_prompt_show_builtin() {
    local output
    output=$(d ai prompt show commit 2>&1)
    
    # Should succeed if commit prompt exists
    local result=$?
    if [ "$result" -eq 0 ]; then
        assert_contains "$output" "commit" "Should show commit prompt content"
    else
        # If it fails, it should indicate prompt not found
        assert_contains "$output" "not found" "Should indicate prompt not found"
    fi
}

# Test prompt show for non-existent prompt
test_ai_prompt_show_nonexistent() {
    local output
    output=$(d ai prompt show nonexistent-prompt 2>&1)
    result=$?
    
    # Should fail
    assert_not_equals "0" "$result" "Should fail for non-existent prompt"
    
    # Should indicate not found
    assert_contains "$output" "not found" "Should indicate prompt not found"
}

# Test prompt add command
test_ai_prompt_add() {
    local output
    output=$(d ai prompt add test-prompt "$TEST_PROMPT_FILE" 2>&1)
    
    # Should succeed
    assert_equals "0" "$?" "Prompt add should succeed with valid file"
    
    # Should confirm addition
    assert_contains "$output" "added successfully" "Should confirm prompt was added"
}

# Test prompt add with non-existent file
test_ai_prompt_add_missing_file() {
    local output
    output=$(d ai prompt add test-prompt "/nonexistent/file" 2>&1)
    result=$?
    
    # Should fail
    assert_not_equals "0" "$result" "Should fail with non-existent source file"
    
    # Should indicate file not found
    assert_contains "$output" "not found" "Should indicate source file not found"
}

# Test prompt add with missing arguments
test_ai_prompt_add_missing_args() {
    local output
    output=$(d ai prompt add 2>&1)
    result=$?
    
    # Should fail
    assert_not_equals "0" "$result" "Should fail with missing arguments"
    
    # Should show usage information
    assert_contains "$output" "Usage\|required" "Should show usage or indicate missing args"
}

# Test prompt command structure
test_ai_prompt_command_structure() {
    # Test invalid subcommand
    local output
    output=$(d ai prompt invalid-command 2>&1)
    result=$?
    
    # Should fail
    assert_not_equals "0" "$result" "Should fail with invalid subcommand"
    
    # Should indicate unknown command
    assert_contains "$output" "Unknown\|help" "Should indicate unknown command or show help"
}
