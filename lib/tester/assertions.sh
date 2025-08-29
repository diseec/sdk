#!/bin/bash
# Test framework assertion functions

# Test state tracking
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0
ASSERTION_COUNT=0
CURRENT_TEST_CASE=""
CURRENT_TEST_FILE=""

# Initialize test state
init_test_state() {
    TEST_COUNT=0
    PASSED_COUNT=0
    FAILED_COUNT=0
    ASSERTION_COUNT=0
    CURRENT_TEST_CASE=""
    CURRENT_TEST_FILE="$1"
}

# Increment test counters
_increment_assertion() {
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
}

_increment_test() {
    TEST_COUNT=$((TEST_COUNT + 1))
}

_increment_passed() {
    PASSED_COUNT=$((PASSED_COUNT + 1))
}

_increment_failed() {
    FAILED_COUNT=$((FAILED_COUNT + 1))
}

# Print test section header
test_section() {
    local title="$1"
    echo -e "\n${COLOR_HIGHLIGHT}${BOLD}=== $title ===${NC}"
}

# Print test case header
test_case() {
    local title="$1"
    CURRENT_TEST_CASE="$title"
    echo -e "\n${COLOR_INFO}Test Case: $title${NC}"
    ASSERTION_COUNT=0
    _increment_test
}

# Assert that a command succeeds
assert_success() {
    local description="$1"
    shift
    _increment_assertion
    
    if "$@" >/dev/null 2>&1; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}Command failed: $*${NC}"
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    local description="$1"
    shift
    _increment_assertion
    
    if ! "$@" >/dev/null 2>&1; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}Command should have failed: $*${NC}"
        return 1
    fi
}

# Assert that two strings are equal
assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    _increment_assertion
    
    if [ "$expected" = "$actual" ]; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}Expected: '$expected'${NC}"
        echo -e "    ${COLOR_MUTED}Actual:   '$actual'${NC}"
        return 1
    fi
}

# Assert that two strings are not equal
assert_not_equals() {
    local description="$1"
    local not_expected="$2"
    local actual="$3"
    _increment_assertion
    
    if [ "$not_expected" != "$actual" ]; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}Should not equal: '$not_expected'${NC}"
        echo -e "    ${COLOR_MUTED}Actual:           '$actual'${NC}"
        return 1
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    _increment_assertion
    
    if echo "$haystack" | grep -q -F "$needle"; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}String: '$haystack'${NC}"
        echo -e "    ${COLOR_MUTED}Should contain: '$needle'${NC}"
        return 1
    fi
}

# Assert that a string does not contain a substring
assert_not_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"
    _increment_assertion
    
    if ! echo "$haystack" | grep -q -F "$needle"; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}String: '$haystack'${NC}"
        echo -e "    ${COLOR_MUTED}Should not contain: '$needle'${NC}"
        return 1
    fi
}

# Assert that a string matches a regex pattern
assert_matches() {
    local description="$1"
    local string="$2"
    local pattern="$3"
    _increment_assertion
    
    if echo "$string" | grep -q -E "$pattern"; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}String: '$string'${NC}"
        echo -e "    ${COLOR_MUTED}Should match pattern: '$pattern'${NC}"
        return 1
    fi
}

# Assert that a function exists
assert_function_exists() {
    local description="$1"
    local function_name="$2"
    _increment_assertion
    
    if declare -f "$function_name" >/dev/null 2>&1; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}Function '$function_name' not found${NC}"
        return 1
    fi
}

# Assert that a variable is set
assert_variable_set() {
    local description="$1"
    local variable_name="$2"
    _increment_assertion
    
    if [ -n "${!variable_name:-}" ]; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}Variable '$variable_name' is not set${NC}"
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local description="$1"
    local file_path="$2"
    _increment_assertion
    
    if [ -f "$file_path" ]; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}File '$file_path' does not exist${NC}"
        return 1
    fi
}

# Assert that a directory exists
assert_directory_exists() {
    local description="$1"
    local dir_path="$2"
    _increment_assertion
    
    if [ -d "$dir_path" ]; then
        echo -e "  ${COLOR_SUCCESS}✔${NC} $description"
        return 0
    else
        echo -e "  ${COLOR_ERROR}✗${NC} $description"
        echo -e "    ${COLOR_MUTED}Directory '$dir_path' does not exist${NC}"
        return 1
    fi
}

# Get test statistics
get_test_stats() {
    echo "Tests: $TEST_COUNT, Assertions: $ASSERTION_COUNT, Passed: $PASSED_COUNT, Failed: $FAILED_COUNT"
}

# Export all assertion functions
export -f test_section test_case
export -f assert_success assert_failure assert_equals assert_not_equals
export -f assert_contains assert_not_contains assert_matches
export -f assert_function_exists assert_variable_set 
export -f assert_file_exists assert_directory_exists
export -f get_test_stats
