#!/bin/bash

# Test file for stdio.sh functions

# Test stdout function
test_stdout_basic() {
    # Test basic log message
    export D_LOG_LEVEL="VERBOSE"
    local result=$(capture_test_log stdout "Test message" 2>&1)
    
    # We don't test the exact format (timestamp varies) but check the content
    assert_contains "$result" "Test message" "stdout should display the basic message"
}

test_stdout_types() {
    # Test different message types
    export D_LOG_LEVEL="VERBOSE"
    
    # Test info message
    local info_result=$(capture_test_log stdout -i "Info message" 2>&1)
    assert_contains "$info_result" "[i]" "stdout info should contain the info icon"
    assert_contains "$info_result" "Info message" "stdout info should contain the message"
    
    # Test error message
    local error_result=$(capture_test_log stdout -e "Error message" 2>&1)
    assert_contains "$error_result" "[E]" "stdout error should contain the error icon"
    assert_contains "$error_result" "Error message" "stdout error should contain the message"
    
    # Test warning message
    local warning_result=$(capture_test_log stdout -w "Warning message" 2>&1)
    assert_contains "$warning_result" "[!]" "stdout warning should contain the warning icon"
    assert_contains "$warning_result" "Warning message" "stdout warning should contain the message"
}

test_stdout_log_levels() {
    # Test different log levels
    
    # Set log level to INFO
    export D_LOG_LEVEL="INFO"
    
    # Debug messages should be suppressed at INFO level
    local debug_result=$(capture_test_log stdout -d "Debug message" 2>&1)
    assert_empty "$debug_result" "Debug message should not appear at INFO level"
    
    # Info messages should appear
    local info_result=$(capture_test_log stdout -i "Info message" 2>&1)
    assert_contains "$info_result" "Info message" "Info message should appear at INFO level"
    
    # Set log level to ERROR
    export D_LOG_LEVEL="ERROR"
    
    # Warning messages should be suppressed at ERROR level
    local warning_result=$(capture_test_log stdout -w "Warning message" 2>&1)
    assert_empty "$warning_result" "Warning message should not appear at ERROR level"
    
    # Error messages should appear
    local error_result=$(capture_test_log stdout -e "Error message" 2>&1)
    assert_contains "$error_result" "Error message" "Error message should appear at ERROR level"
}

test_stdout_custom_icon_ansi() {
    # Test custom icon and ANSI code
    export D_LOG_LEVEL="VERBOSE"
    
    local result=$(capture_test_log stdout --icon="X" --ansi="36" "Custom message" 2>&1)
    assert_contains "$result" "[X]" "stdout should display custom icon"
    assert_contains "$result" "Custom message" "stdout should display the custom message"
}

# Test confirm function
test_confirm_yes_input() {
    # Test confirm with 'yes' input
    
    # Simulate 'y' input using here string
    local result=$(echo "y" | confirm "Confirm test?" echo "Confirmation successful")
    
    # Check if the confirmation action was performed
    assert_contains "$result" "Confirmation successful" "confirm should execute the action on 'yes' input"
}

test_confirm_no_input() {
    # Test confirm with 'no' input
    
    # Simulate 'n' input using here string
    local result=$(echo "n" | confirm "Confirm test?" echo "Confirmation successful")
    
    # Check that the confirmation action was not performed
    assert_not_contains "$result" "Confirmation successful" "confirm should not execute the action on 'no' input"
}

test_confirm_if_statement() {
    # Test confirm in an if statement
    
    # Simulate 'y' input and use in if statement
    if echo "y" | confirm "Confirm test?"; then
        success=true
    else
        success=false
    fi
    
    assert_equals "true" "$success" "confirm should return 0 (success) on 'yes' input"
    
    # Simulate 'n' input and use in if statement
    if echo "n" | confirm "Confirm test?"; then
        success=true
    else
        success=false
    fi
    
    assert_equals "false" "$success" "confirm should return 1 (failure) on 'no' input"
}

# Test display_help function
test_display_help_output() {
    # Test display_help output format
    export D_LOG_LEVEL="VERBOSE"
    
    local result=$(capture_test_log display_help "command1" "Description 1" "command2" "Description 2" 2>&1)
    
    assert_contains "$result" "command1" "display_help should show command names"
    assert_contains "$result" "Description 1" "display_help should show command descriptions"
    assert_contains "$result" "command2" "display_help should show multiple commands"
    assert_contains "$result" "Description 2" "display_help should show multiple descriptions"
}
