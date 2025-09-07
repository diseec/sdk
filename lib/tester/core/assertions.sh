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
    
    TESTER_TOTAL_TESTS=$((TESTER_TOTAL_TESTS + 1))
    
    if [ "$success" = "true" ]; then
        TESTER_PASSED_TESTS=$((TESTER_PASSED_TESTS + 1))
        # Always call the reporter function for consistent handling
        sdk_tester_show_assertion_result "true" "$message" "$test_name"
        return 0
    else
        TESTER_FAILED_TESTS=$((TESTER_FAILED_TESTS + 1))
        # Always call the reporter function for consistent handling
        sdk_tester_show_assertion_result "false" "$message" "$test_name"
        
        # Show details only if verbose
        if [ "$TESTER_VERBOSE" = "true" ] && [ -n "$expected" ] && [ -n "$actual" ]; then
            printf "\n        \033[90mexpected:\033[0m \033[97m%s\033[0m\n" "$expected"
            printf "        \033[90mactual  :\033[0m \033[97m%s\033[0m" "$actual"
        fi
        
        if [ "$TESTER_FAIL_FAST" = "true" ]; then
            printf "\n      \033[31m[!]\033[0m \033[90mFail-fast mode enabled, stopping\033[0m\n"
            return 1
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
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "$expected" "$actual"
    fi
}

# Assert that two values are not equal  
assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-"Values should not be equal"}"
    
    if [ "$expected" != "$actual" ]; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "not $expected" "$actual"
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-"String should contain substring"}"
    
    if echo "$haystack" | grep -q "$needle"; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "contains '$needle'" "'$haystack'"
    fi
}

# Assert that a string does not contain a substring
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-"String should not contain substring"}"
    
    if ! echo "$haystack" | grep -q "$needle"; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "not contains '$needle'" "'$haystack'"
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file_path="$1"
    local message="${2:-"File should exist: $file_path"}"
    
    if [ -f "$file_path" ]; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "file exists" "file not found"
    fi
}

# Assert that a file does not exist
assert_file_not_exists() {
    local file_path="$1"
    local message="${2:-"File should not exist: $file_path"}"
    
    if [ ! -f "$file_path" ]; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "file not exists" "file exists"
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local dir_path="$1"
    local message="${2:-"Directory should exist: $dir_path"}"
    
    if [ -d "$dir_path" ]; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "directory exists" "directory not found"
    fi
}

# Assert that a command succeeds (exit code 0)
assert_command_success() {
    local command="$1"
    local message="${2:-"Command should succeed: $command"}"
    
    if eval "$command" >/dev/null 2>&1; then
        _tester_assert_result "true" "$message"
    else
        local exit_code=$?
        _tester_assert_result "false" "$message" "exit code 0" "exit code $exit_code"
    fi
}

# Assert that a command fails (non-zero exit code)
assert_command_fails() {
    local command="$1"
    local message="${2:-"Command should fail: $command"}"
    
    if ! eval "$command" >/dev/null 2>&1; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "non-zero exit code" "exit code 0"
    fi
}

# Assert that a value is empty
assert_empty() {
    local value="$1"
    local message="${2:-"Value should be empty"}"
    
    if [ -z "$value" ]; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "empty value" "'$value'"
    fi
}

# Assert that a value is not empty
assert_not_empty() {
    local value="$1"
    local message="${2:-"Value should not be empty"}"
    
    if [ -n "$value" ]; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "non-empty value" "empty value"
    fi
}

# Assert that a value matches a regex pattern
assert_matches() {
    local value="$1"
    local pattern="$2"
    local message="${3:-"Value should match pattern: $pattern"}"
    
    if echo "$value" | grep -qE "$pattern"; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "matches '$pattern'" "'$value'"
    fi
}

# Assert that a numeric value is greater than another
assert_greater_than() {
    local value="$1"
    local threshold="$2"
    local message="${3:-"Value should be greater than $threshold"}"
    
    if [ "$value" -gt "$threshold" ] 2>/dev/null; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "> $threshold" "$value"
    fi
}

# Assert that a numeric value is less than another
assert_less_than() {
    local value="$1"
    local threshold="$2"
    local message="${3:-"Value should be less than $threshold"}"
    
    if [ "$value" -lt "$threshold" ] 2>/dev/null; then
        _tester_assert_result "true" "$message"
    else
        _tester_assert_result "false" "$message" "< $threshold" "$value"
    fi
}

# Skip a test with a reason
skip_test() {
    local reason="${1:-"Test skipped"}"
    TESTER_SKIPPED_TESTS=$((TESTER_SKIPPED_TESTS + 1))
    TESTER_TOTAL_TESTS=$((TESTER_TOTAL_TESTS + 1))
    
    if [ "$TESTER_VERBOSE" = "true" ]; then
        printf "  \033[33m⊘\033[0m"
    fi
    return 0
}

# Fail a test immediately with a custom message
fail_test() {
    local message="${1:-"Test failed"}"
    _tester_assert_result "false" "$message"
    return 1
}
