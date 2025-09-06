#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ UTILITIES TEST EXAMPLE                                                  ┃
# ┃ Testing utility functions and more complex scenarios                    ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Test mathematical operations
test_math_operations() {
    local result
    
    # Test basic arithmetic
    result=$((5 + 3))
    assert_equals 8 "$result" "5 + 3 should equal 8"
    
    result=$((10 * 2))
    assert_equals 20 "$result" "10 * 2 should equal 20"
    
    # Test comparison operations
    assert_greater_than 100 99 "100 should be greater than 99"
    assert_less_than 0 1 "0 should be less than 1"
}

# Test array operations (bash arrays)
test_array_operations() {
    local test_array=("apple" "banana" "cherry")
    local array_length=${#test_array[@]}
    
    assert_equals 3 "$array_length" "Array should have 3 elements"
    assert_equals "apple" "${test_array[0]}" "First element should be apple"
    assert_equals "cherry" "${test_array[2]}" "Third element should be cherry"
}

# Test environment variable handling
test_environment_variables() {
    # Set a test environment variable
    export TEST_ENV_VAR="test_value"
    
    assert_not_empty "$TEST_ENV_VAR" "TEST_ENV_VAR should be set"
    assert_equals "test_value" "$TEST_ENV_VAR" "TEST_ENV_VAR should have correct value"
    
    # Test unsetting
    unset TEST_ENV_VAR
    assert_empty "$TEST_ENV_VAR" "TEST_ENV_VAR should be empty after unset"
}

# Test text processing operations
test_text_processing() {
    local text="Hello World 123"
    
    # Test case conversion (if available)
    local uppercase
    uppercase=$(echo "$text" | tr '[:lower:]' '[:upper:]')
    assert_equals "HELLO WORLD 123" "$uppercase" "Text should be converted to uppercase"
    
    # Test word extraction
    local first_word
    first_word=$(echo "$text" | cut -d' ' -f1)
    assert_equals "Hello" "$first_word" "First word should be Hello"
    
    # Test pattern matching with grep
    assert_command_success "echo '$text' | grep -q 'World'" "Text should contain World"
    assert_command_fails "echo '$text' | grep -q 'xyz'" "Text should not contain xyz"
}

# Test file content operations
test_file_content_operations() {
    local test_file="/tmp/tester_content_test.txt"
    local test_content="Line 1\nLine 2\nLine 3"
    
    # Create test file
    echo -e "$test_content" > "$test_file"
    assert_file_exists "$test_file" "Test file should be created"
    
    # Test file content
    local line_count
    line_count=$(wc -l < "$test_file" | tr -d ' ')
    assert_equals 3 "$line_count" "File should have 3 lines"
    
    # Test content search
    assert_command_success "grep -q 'Line 2' '$test_file'" "File should contain Line 2"
    
    # Clean up
    rm -f "$test_file"
    assert_file_not_exists "$test_file" "Test file should be deleted"
}

# Test network-related operations (if applicable)
test_network_operations() {
    # Test basic connectivity (localhost should always be reachable)
    if command -v ping >/dev/null 2>&1; then
        assert_command_success "ping -c1 127.0.0.1 >/dev/null 2>&1" "Localhost ping should succeed"
    else
        skip_test "Ping command not available"
    fi
}

# Test date and time operations
test_date_time_operations() {
    local current_year
    current_year=$(date +%Y)
    
    # Current year should be reasonable (between 2020 and 2030)
    assert_greater_than "$current_year" 2020 "Current year should be after 2020"
    assert_less_than "$current_year" 2030 "Current year should be before 2030"
    
    # Test date formatting
    local formatted_date
    formatted_date=$(date +%Y-%m-%d)
    assert_matches "$formatted_date" "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" "Date should be in YYYY-MM-DD format"
}

# Test error handling
test_error_handling() {
    # Test that errors are properly caught
    local error_output
    error_output=$(ls /nonexistent/path 2>&1) || true
    
    assert_not_empty "$error_output" "Error command should produce output"
    assert_contains "$error_output" "No such file or directory" "Error should mention missing file"
}
