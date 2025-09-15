#!/bin/bash

# Example test demonstrating the use of the capture_test_log function

test_basic_capture() {
    # Run a command and capture_test_log its output directly
    local output=$(capture_test_log echo "Hello, world!")
    
    # Make assertions on the output
    assert_equals "Hello, world!" "$output" "Output should match expected string"
}

test_command_capture() {
    # Run D command and capture_test_log
    local output=$(capture_test_log D --version)
    
    # Make assertions on the captured output - use case-insensitive matching for flexibility
    assert_contains "$(echo "$output" | tr '[:upper:]' '[:lower:]')" "version" "Command output should contain version information"
}

test_command_error_capture() {
    # Run a command that will likely fail and capture_test_log its error output
    # Using a clearly non-existent command to guarantee failure
    local output=$(capture_test_log "command_that_does_not_exist_at_all" || true)
    
    # Make assertions on the error output - check for "command not found" which is what bash typically returns
    assert_contains "$output" "not found" "Error message should indicate command not found"
}

test_capture_with_complex_command() {
    # Run a more complex command chain using string syntax
    local output=$(capture_test_log "echo 'Starting complex command' && ls -la | grep test || echo 'No test files found' && echo 'Command completed'")
    
    # Make targeted assertions
    assert_contains "$output" "Starting complex command" "Starting message should be present"
    assert_contains "$output" "Command completed" "Completion message should be present"
}

# test_capture_with_multiple_logs_then_fail() {
#     # First command generates some output
#     local output1=$(capture_test_log "echo 'First log entry: This should be captured' && echo 'This is multiline output' && echo 'With several lines'")
    
#     # Second command generates more output
#     local output2=$(capture_test_log "ls -la / | head -5")
    
#     # Third command runs a command that produces
#     local output3=$(capture_test_log "find /tmp -type f -name 'test*' 2>&1 | head -3")
    
#     # Print some info about what we're doing
#     echo "Preparing to fail the test after collecting logs..."
    
#     # Make a valid assertion first
#     assert_contains "$output1" "multiline output" "First command output should contain expected text"
    
#     # Now deliberately fail the test to see the logs
#     assert_equals "This will fail" "This is not equal" "This assertion is meant to fail to show logs"
# }
