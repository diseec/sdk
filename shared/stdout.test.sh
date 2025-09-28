#!/bin/bash

# Test file for stdio.sh functions

# Helper functions to capture stdout and stderr separately
capture_stdout() {
    "$@" 2>/dev/null
}

capture_stderr() {
    "$@" 2>&1 >/dev/null
}

# Test stdout function
test_stdout_basic() {
    # Test basic log message
    export D_GLOB_LOG_LEVEL="VERBOSE"
    
    # Capture stdout - should be empty
    local stdout_result=$(capture_stdout stdout "Test message")
    
    # Capture stderr - should contain the message
    local stderr_result=$(capture_stderr stdout "Test message")
    
    # Verify stdout is empty (no messages)
    assert_empty "$stdout_result" "stdout function should not write to stdout"
    
    # Verify stderr contains the message
    assert_contains "$stderr_result" "Test message" "stdout should write the basic message to stderr"
}

test_stdout_types() {
    # Test different message types
    export D_GLOB_LOG_LEVEL="VERBOSE"
    
    # Test info message
    local info_stdout=$(capture_stdout stdout -i "Info message")
    local info_stderr=$(capture_stderr stdout -i "Info message")
    
    assert_empty "$info_stdout" "stdout info should not write to stdout"
    assert_contains "$info_stderr" "[i]" "stdout info should contain the info icon in stderr"
    assert_contains "$info_stderr" "Info message" "stdout info should contain the message in stderr"
    
    # Test error message
    local error_stdout=$(capture_stdout stdout -e "Error message")
    local error_stderr=$(capture_stderr stdout -e "Error message")
    
    assert_empty "$error_stdout" "stdout error should not write to stdout"
    assert_contains "$error_stderr" "[E]" "stdout error should contain the error icon in stderr"
    assert_contains "$error_stderr" "Error message" "stdout error should contain the message in stderr"
    
    # Test warning message
    local warning_stdout=$(capture_stdout stdout -w "Warning message")
    local warning_stderr=$(capture_stderr stdout -w "Warning message")
    
    assert_empty "$warning_stdout" "stdout warning should not write to stdout"
    assert_contains "$warning_stderr" "[!]" "stdout warning should contain the warning icon in stderr"
    assert_contains "$warning_stderr" "Warning message" "stdout warning should contain the message in stderr"
}

test_stdout_log_levels() {
    # Test different log levels
    
    # Set log level to INFO
    export D_GLOB_LOG_LEVEL="INFO"
    
    # Debug messages should be suppressed at INFO level
    local debug_stdout=$(capture_stdout stdout -d "Debug message")
    local debug_stderr=$(capture_stderr stdout -d "Debug message")
    
    assert_empty "$debug_stdout" "Debug output should not appear in stdout"
    assert_empty "$debug_stderr" "Debug message should not appear at INFO level in stderr"
    
    # Info messages should appear
    local info_stdout=$(capture_stdout stdout -i "Info message")
    local info_stderr=$(capture_stderr stdout -i "Info message")
    
    assert_empty "$info_stdout" "Info output should not appear in stdout"
    assert_contains "$info_stderr" "Info message" "Info message should appear at INFO level in stderr"
    
    # Set log level to ERROR
    export D_GLOB_LOG_LEVEL="ERROR"
    
    # Warning messages should be suppressed at ERROR level
    local warning_stdout=$(capture_stdout stdout -w "Warning message")
    local warning_stderr=$(capture_stderr stdout -w "Warning message")
    
    assert_empty "$warning_stdout" "Warning output should not appear in stdout"
    assert_empty "$warning_stderr" "Warning message should not appear at ERROR level in stderr"
    
    # Error messages should appear
    local error_stdout=$(capture_stdout stdout -e "Error message")
    local error_stderr=$(capture_stderr stdout -e "Error message")
    
    assert_empty "$error_stdout" "Error output should not appear in stdout"
    assert_contains "$error_stderr" "Error message" "Error message should appear at ERROR level in stderr"
}

test_stdout_custom_icon_ansi() {
    # Test custom icon and ANSI code
    export D_GLOB_LOG_LEVEL="VERBOSE"
    
    local stdout_result=$(capture_stdout stdout --icon="X" --ansi="36" "Custom message")
    local stderr_result=$(capture_stderr stdout --icon="X" --ansi="36" "Custom message")
    
    assert_empty "$stdout_result" "Custom message should not appear in stdout"
    assert_contains "$stderr_result" "[X]" "stdout should display custom icon in stderr"
    assert_contains "$stderr_result" "Custom message" "stdout should display the custom message in stderr"
}

# Test command substitution behavior
test_stdout_in_command_substitution() {
    # Test that command substitution doesn't capture stderr output
    export D_GLOB_LOG_LEVEL="VERBOSE"
    
    # This function outputs a message to stderr via stdout function
    # and returns a string to stdout directly
    log_and_return() {
        stdout "Log message to stderr" 2>/dev/null
        echo "Actual return value"
    }
    
    # Capture the result of command substitution
    local result=$(log_and_return)
    
    # Only the actual return value should be captured
    assert_equals "Actual return value" "$result" "Command substitution should only capture stdout"
}

# Test processing flag
test_stdout_processing() {
    # Test processing animation flag
    export D_GLOB_LOG_LEVEL="VERBOSE"
    
    # Capture output to stderr with processing flag
    local stdout_result=$(capture_stdout stdout --processing "Processing message")
    local stderr_result=$(capture_stderr stdout --processing "Processing message")
    
    assert_empty "$stdout_result" "Processing message should not appear in stdout"
    assert_contains "$stderr_result" "Processing message" "stdout should display processing message in stderr"
}
