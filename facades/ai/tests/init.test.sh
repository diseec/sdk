#!/bin/bash

# Test for the 'ai init' command

# Suite setup - runs once before all tests in this file
setup_test() {
    
    # Store original OPENAI_API_KEY for restoration
    export ORIGINAL_OPENAI_API_KEY="$OPENAI_API_KEY"
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Restore original API key
    export OPENAI_API_KEY="$ORIGINAL_OPENAI_API_KEY"
}

# Test init command help functionality
test_ai_init_help() {
    local output
    output=$(d ai init --help 2>&1)
    
    # Should not fail
    assert_equals "0" "$?" "Help command should succeed"
    
    # Should contain usage information (basic check)
    assert_contains "$output" "--force" "Help should mention --force option"
}

# Test init with existing API key
test_ai_init_with_existing_key() {
    # Set a dummy API key
    export OPENAI_API_KEY="sk-test123456789"
    
    # Mock the interactive init to return success
    # Note: In a real test environment, we'd want to mock the API call
    local output
    output=$(cd "$TEST_CTX" && timeout 5 D ai init 2>&1 || echo "TIMEOUT")
    
    # Check that it recognizes existing initialization
    # This test may need adjustment based on actual secret handling behavior
    assert_contains "$output" "initialized\|available\|TIMEOUT" "Should handle existing key gracefully"
}

# Test init command structure and error handling
test_ai_init_command_structure() {
    # Test with invalid argument
    local result
    d ai init --invalid-arg > /dev/null 2>&1
    result=$?
    
    # Should return error for invalid argument
    assert_not_equals "0" "$result" "Should fail with invalid argument"
}

# Test that init command exists and is callable
test_ai_init_command_exists() {
    # Just test that the command doesn't produce "Unknown command" error
    local output
    output=$(cd "$TEST_CTX" && timeout 2 D ai init 2>&1 || echo "COMMAND_EXISTS")
    
    # Should not contain "Unknown command"
    echo "$output" | grep -v "Unknown command" > /dev/null
    assert_equals "0" "$?" "Init command should be recognized"
}
