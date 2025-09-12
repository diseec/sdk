#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TESTER ASSERTION FUNCTIONS                                              ┃
# ┃ Beautiful and easy-to-use assertion functions for shell script testing ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Core assertion result handler
_tester_assert_result() {
    local success="$1"
    local message="$2"
    local expected="${3:-}"
    local actual="${4:-}"
    local test_name="${TESTER_CURRENT_TEST:-unknown}"
    local assert_func="${5:-UNDEFINED}"
    
    TESTER_TOTAL_TESTS=$((TESTER_TOTAL_TESTS + 1))
    
    # Prefix message with assertion function name for clarity
    local prefixed_message="[ASSERT][$assert_func] $message"
    
    if [ "$success" = "true" ]; then
        TESTER_PASSED_TESTS=$((TESTER_PASSED_TESTS + 1))
        # Always call the reporter function for consistent handling
        sdk_tester_show_assertion_result "true" "$prefixed_message" "$test_name"
        return 0
    else
        TESTER_FAILED_TESTS=$((TESTER_FAILED_TESTS + 1))
        # Always call the reporter function for consistent handling
        sdk_tester_show_assertion_result "false" "$prefixed_message" "$test_name"
        
        # Record the assertion failure in the test result file
        if [ -n "$TEST_WORKSPACE" ] && [ -d "$TEST_WORKSPACE" ]; then
            echo "$TESTER_FAILURE_KEY $prefixed_message" >> "$TESTER_RESULT_FILE"
            
            # Include details if available
            if [ -n "$expected" ] && [ -n "$actual" ]; then
                echo "  Expected: $expected" >> "$TESTER_RESULT_FILE"
                echo "  Actual:   $actual" >> "$TESTER_RESULT_FILE"
            fi
        fi
        
        # Show details only if verbose
        if [ "$TESTER_VERBOSE" = "true" ] && [ -n "$expected" ] && [ -n "$actual" ]; then
            # Strip ANSI color codes from expected and actual values
            local expected_clean=$(echo "$expected" | sed 's/\x1b\[[0-9;]*m//g')
            local actual_clean=$(echo "$actual" | sed 's/\x1b\[[0-9;]*m//g')
            
            # Format in a diff-like style with + and - prefixes
            printf "\n"
            # Handle each line of expected output with + prefix (green)
            echo "$expected_clean" | while IFS= read -r line || [ -n "$line" ]; do
                printf "      \033[32m+\033[0m %s\n" "$line"
            done
            
            # Handle each line of actual output with - prefix (red)
            echo "$actual_clean" | while IFS= read -r line || [ -n "$line" ]; do
                printf "      \033[31m-\033[0m %s\n" "$line"
            done
        fi
        
        return 1
    fi
}

# Assert that two values are equal
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-"Values should be equal"}"
    
    if [ "$expected" = "$actual" ]; then
        _tester_assert_result "true" "$message" "" "" "EQUALS"
    else
        _tester_assert_result "false" "$message" "$expected" "$actual" "EQUALS"
    fi
}

# Assert that two values are not equal  
assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-"Values should not be equal"}"
    
    if [ "$expected" != "$actual" ]; then
        _tester_assert_result "true" "$message" "" "" "NOT_EQUALS"
    else
        _tester_assert_result "false" "$message" "any value except: $expected" "$actual" "NOT_EQUALS"
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-"String should contain substring"}"
    
    if echo "$haystack" | grep -q "$needle"; then
        _tester_assert_result "true" "$message" "" "" "CONTAINS"
    else
        _tester_assert_result "false" "$message" "$needle" "$haystack" "CONTAINS"
    fi
}

# Assert that a string does not contain a substring
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-"String should not contain substring"}"
    
    if ! echo "$haystack" | grep -q "$needle"; then
        _tester_assert_result "true" "$message" "" "" "NOT_CONTAINS"
    else
        _tester_assert_result "false" "$message" "should not contain: $needle" "$haystack" "NOT_CONTAINS"
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file_path="$1"
    local message="${2:-"File should exist: $file_path"}"
    
    if [ -f "$file_path" ]; then
        _tester_assert_result "true" "$message" "" "" "FILE_EXISTS"
    else
        _tester_assert_result "false" "$message" "file should exist: $file_path" "file not found" "FILE_EXISTS"
    fi
}

# Assert that a file does not exist
assert_file_not_exists() {
    local file_path="$1"
    local message="${2:-"File should not exist: $file_path"}"
    
    if [ ! -f "$file_path" ]; then
        _tester_assert_result "true" "$message" "" "" "FILE_NOT_EXISTS"
    else
        _tester_assert_result "false" "$message" "file should not exist: $file_path" "file exists" "FILE_NOT_EXISTS"
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local dir_path="$1"
    local message="${2:-"Directory should exist: $dir_path"}"
    
    if [ -d "$dir_path" ]; then
        _tester_assert_result "true" "$message" "" "" "DIR_EXISTS"
    else
        _tester_assert_result "false" "$message" "directory should exist: $dir_path" "directory not found" "DIR_EXISTS"
    fi
}

# Assert that a command succeeds (exit code 0)
assert_command_success() {
    local command="$1"
    local message="${2:-"Command should succeed: $command"}"
    
    if eval "$command" >/dev/null 2>&1; then
        _tester_assert_result "true" "$message" "" "" "CMD_SUCCESS"
    else
        local exit_code=$?
        _tester_assert_result "false" "$message" "command should succeed: '$command'" "exit code $exit_code" "CMD_SUCCESS"
    fi
}

# Assert that a command fails (non-zero exit code)
assert_command_fails() {
    local command="$1"
    local message="${2:-"Command should fail: $command"}"
    
    if ! eval "$command" >/dev/null 2>&1; then
        _tester_assert_result "true" "$message" "" "" "CMD_FAILS"
    else
        _tester_assert_result "false" "$message" "command should fail: '$command'" "exit code 0" "CMD_FAILS"
    fi
}

# Assert that a value is empty
assert_empty() {
    local value="$1"
    local message="${2:-"Value should be empty"}"
    
    if [ -z "$value" ]; then
        _tester_assert_result "true" "$message" "" "" "EMPTY"
    else
        _tester_assert_result "false" "$message" "empty string" "$value" "EMPTY"
    fi
}

# Assert that a value is not empty
assert_not_empty() {
    local value="$1"
    local message="${2:-"Value should not be empty"}"
    
    if [ -n "$value" ]; then
        _tester_assert_result "true" "$message" "" "" "NOT_EMPTY"
    else
        _tester_assert_result "false" "$message" "non-empty string" "empty string" "NOT_EMPTY"
    fi
}

# Assert that a value matches a regex pattern
assert_matches() {
    local value="$1"
    local pattern="$2"
    local message="${3:-"Value should match pattern: $pattern"}"
    
    if echo "$value" | grep -qE "$pattern"; then
        _tester_assert_result "true" "$message" "" "" "MATCHES"
    else
        _tester_assert_result "false" "$message" "pattern: $pattern" "$value" "MATCHES"
    fi
}

# Assert that a numeric value is greater than another
assert_greater_than() {
    local value="$1"
    local threshold="$2"
    local message="${3:-"Value should be greater than $threshold"}"
    
    if [ "$value" -gt "$threshold" ] 2>/dev/null; then
        _tester_assert_result "true" "$message" "" "" "GREATER_THAN"
    else
        _tester_assert_result "false" "$message" "> $threshold" "$value" "GREATER_THAN"
    fi
}

# Assert that a numeric value is less than another
assert_less_than() {
    local value="$1"
    local threshold="$2"
    local message="${3:-"Value should be less than $threshold"}"
    
    if [ "$value" -lt "$threshold" ] 2>/dev/null; then
        _tester_assert_result "true" "$message" "" "" "LESS_THAN"
    else
        _tester_assert_result "false" "$message" "< $threshold" "$value" "LESS_THAN"
    fi
}

# Skip a test with a reason
skip_test() {
    local reason="${1:-"Test skipped"}"
    TESTER_SKIPPED_TESTS=$((TESTER_SKIPPED_TESTS + 1))
    TESTER_TOTAL_TESTS=$((TESTER_TOTAL_TESTS + 1))
    
    # Add the SKIP prefix to the reason
    local prefixed_reason="[SKIP] $reason"
    
    if [ "$TESTER_VERBOSE" = "true" ]; then
        printf "  \033[33m⊘\033[0m"
    fi
    return 0
}

# Fail a test immediately with a custom message
fail_test() {
    local message="${1:-"Test failed"}"
    _tester_assert_result "false" "$message" "" "" "FAIL"
    return 1
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ EXTENDED ASSERTIONS FOR SECRETS TESTING                                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Assert that a string is a valid hexadecimal key of specific length
assert_valid_hex_key() {
    local value="$1"
    local expected_length="${2:-64}"
    local message="${3:-"Value should be a valid $expected_length-character hex key"}"
    
    local actual_length=$(echo "$value" | wc -c | tr -d ' ')
    # Account for newline character
    local expected_with_newline=$((expected_length + 1))
    
    if [ "$actual_length" -eq "$expected_with_newline" ] && echo "$value" | grep -qE "^[0-9a-f]{$expected_length}$"; then
        _tester_assert_result "true" "$message" "" "" "VALID_HEX"
    else
        _tester_assert_result "false" "$message" "$expected_length-char hex key" "$actual_length-char: '$value'" "VALID_HEX"
    fi
}

# Assert that output contains error indicators
assert_contains_error() {
    local output="$1"
    local message="${2:-"Output should contain error indicators"}"
    
    if echo "$output" | grep -qE "(error|ERROR|fail|FAIL|✖|⚠️|\[!\])"; then
        _tester_assert_result "true" "$message" "" "" "CONTAINS_ERROR"
    else
        _tester_assert_result "false" "$message" "should contain error indicators" "$output" "CONTAINS_ERROR"
    fi
}

# Assert that output contains success indicators
assert_contains_success() {
    local output="$1"
    local message="${2:-"Output should contain success indicators"}"
    
    if echo "$output" | grep -qE "(success|SUCCESS|✓|✔|added|configured|initialized|removed)"; then
        _tester_assert_result "true" "$message" "" "" "CONTAINS_SUCCESS"
    else
        _tester_assert_result "false" "$message" "should contain success indicators" "$output" "CONTAINS_SUCCESS"
    fi
}

# Assert that a command times out (useful for interactive commands)
assert_command_times_out() {
    local timeout_seconds="$1"
    local command="$2"
    local message="${3:-"Command should timeout after $timeout_seconds seconds"}"
    
    if timeout "$timeout_seconds" bash -c "$command" >/dev/null 2>&1; then
        # Command completed within timeout - this might be unexpected
        _tester_assert_result "false" "$message" "command should timeout: '$command'" "completed successfully" "CMD_TIMEOUT"
    else
        local exit_code=$?
        if [ "$exit_code" -eq 124 ]; then
            # Command timed out (timeout exit code is 124)
            _tester_assert_result "true" "$message" "" "" "CMD_TIMEOUT"
        else
            # Command failed for other reasons
            _tester_assert_result "false" "$message" "command should timeout: '$command'" "exit code $exit_code" "CMD_TIMEOUT"
        fi
    fi
}

# Assert that a string has minimum length
assert_min_length() {
    local value="$1"
    local min_length="$2"
    local message="${3:-"Value should have minimum length of $min_length"}"
    
    local actual_length=$(echo -n "$value" | wc -c | tr -d ' ')
    
    if [ "$actual_length" -ge "$min_length" ]; then
        _tester_assert_result "true" "$message" "" "" "MIN_LENGTH"
    else
        _tester_assert_result "false" "$message" ">= $min_length characters" "$actual_length characters" "MIN_LENGTH"
    fi
}

# Assert that a string has maximum length
assert_max_length() {
    local value="$1"
    local max_length="$2"
    local message="${3:-"Value should have maximum length of $max_length"}"
    
    local actual_length=$(echo -n "$value" | wc -c | tr -d ' ')
    
    if [ "$actual_length" -le "$max_length" ]; then
        _tester_assert_result "true" "$message" "" "" "MAX_LENGTH"
    else
        _tester_assert_result "false" "$message" "<= $max_length characters" "$actual_length characters" "MAX_LENGTH"
    fi
}
