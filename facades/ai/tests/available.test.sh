#!/bin/bash

# Test for the 'ai available' command

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

# Test availability check with missing API key
test_ai_available_without_api_key() {
    # Clear API key
    unset OPENAI_API_KEY
    
    # Run availability check and capture exit code
    local result
    d ai available --quiet > /dev/null 2>&1
    result=$?
    
    # Should return non-zero exit code when API key is missing
    assert_not_equals "0" "$result" "Should fail when OPENAI_API_KEY is not set"
}

# Test availability check with API key present
test_ai_available_with_api_key() {
    # Set a dummy API key for testing
    export OPENAI_API_KEY="sk-test123456789"
    
    # Run availability check
    local result
    d ai available --quiet > /dev/null 2>&1
    result=$?
    
    # Should return zero exit code when API key is present
    assert_equals "0" "$result" "Should succeed when OPENAI_API_KEY is set"
}

# Test availability check output format
test_ai_available_output_format() {
    # Set a dummy API key for testing
    export OPENAI_API_KEY="sk-test123456789abcdef"
    
    # Run availability check and capture output
    local output
    output=$(d ai available 2>&1)
    
    # Check that output contains expected information
    assert_contains "$output" "AI services are available" "Output should confirm availability"
    assert_contains "$output" "API Endpoint" "Output should show API endpoint"
    assert_contains "$output" "Default Model" "Output should show default model"
    assert_contains "$output" "sk-test123" "Output should show masked API key start"
    assert_contains "$output" "cdef" "Output should show masked API key end"
}

# Test availability function directly
test_sdk_fac_ai_is_available_function() {
    # Clear API key first
    unset OPENAI_API_KEY
    
    # Should return false without API key
    d ai function sdk_fac_ai_is_available
    local result=$?
    assert_not_equals "0" "$result" "Function should return false without API key"
    
    # Set API key and test again
    export OPENAI_API_KEY="sk-test123"
    d ai function sdk_fac_ai_is_available
    result=$?
    assert_equals "0" "$result" "Function should return true with API key"
}
