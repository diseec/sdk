#!/bin/bash
# Test framework assertion functions

# Print test section header
test_section() {
    local title="$1"
    format_output "section" "$title"
}

# Print test case header
test_case() {
    local title="$1"
    export CURRENT_TEST_CASE="$title"
    format_output "test" "$title"
    ASSERTION_COUNT=0
    TEST_COUNT=$((TEST_COUNT + 1))
}

# Function to mark a test as skipped
test_skip() {
    local reason="$1"
    format_output "skip" "$reason"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
}

# Assert that a command succeeds
assert_success() {
    local description="$1"
    shift
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if "$@" >/dev/null 2>&1; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Command failed: $*${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    local description="$1"
    shift
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if ! "$@" >/dev/null 2>&1; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Command should have failed: $*${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that two strings are equal
assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if [ "$expected" = "$actual" ]; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Expected: '$expected'${NC}"
        echo -e "    ${COLOR_MUTED}Actual:   '$actual'${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that two strings are not equal
assert_not_equals() {
    local description="$1"
    local not_expected="$2"
    local actual="$3"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if [ "$not_expected" != "$actual" ]; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Should not equal: '$not_expected'${NC}"
        echo -e "    ${COLOR_MUTED}Actual:           '$actual'${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if echo "$haystack" | grep -q -F "$needle"; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}String: '$haystack'${NC}"
        echo -e "    ${COLOR_MUTED}Should contain: '$needle'${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a string does not contain a substring
assert_not_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if ! echo "$haystack" | grep -q -F "$needle"; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}String: '$haystack'${NC}"
        echo -e "    ${COLOR_MUTED}Should not contain: '$needle'${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a string matches a regex pattern
assert_matches() {
    local description="$1"
    local string="$2"
    local pattern="$3"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if echo "$string" | grep -q -E "$pattern"; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}String: '$string'${NC}"
        echo -e "    ${COLOR_MUTED}Should match pattern: '$pattern'${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a function exists
assert_function_exists() {
    local description="$1"
    local function_name="$2"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if declare -f "$function_name" >/dev/null 2>&1; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Function '$function_name' not found${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a variable is set
assert_variable_set() {
    local description="$1"
    local variable_name="$2"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if [ -n "${!variable_name:-}" ]; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Variable '$variable_name' is not set${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local description="$1"
    local file_path="$2"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if [ -f "$file_path" ]; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}File '$file_path' does not exist${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a directory exists
assert_directory_exists() {
    local description="$1"
    local dir_path="$2"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if [ -d "$dir_path" ]; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Directory '$dir_path' does not exist${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Get test statistics
get_test_stats() {
    echo "Tests: $TEST_COUNT, Assertions: $ASSERTION_COUNT, Passed: $PASSED_COUNT, Failed: $FAILED_COUNT, Skipped: $SKIPPED_COUNT"
}

# Export all assertion functions
export -f test_section test_case test_skip
export -f assert_success assert_failure assert_equals assert_not_equals
export -f assert_contains assert_not_contains assert_matches
export -f assert_function_exists assert_variable_set 
export -f assert_file_exists assert_directory_exists
export -f get_test_stats
