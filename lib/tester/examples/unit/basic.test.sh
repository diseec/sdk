#!/bin/bash
# Example unit test for SDK core functions

# Source the unit testing framework
source "$D_SDK_DIR/lib/testing/frameworks/unit/framework.sh"

# Initialize unit test environment
unit_init

# Test basic math functions
test_section "Math Utility Functions"

# Test addition
test_case "Addition function"
# Define a function to test
add() {
    echo $(($1 + $2))
}

result=$(add 2 3)
assert_equals "2 + 3 should equal 5" "5" "$result"

# Test string utilities
test_section "String Utility Functions"

test_case "String contains function"
string="Hello, World!"
assert_contains "String should contain 'World'" "$string" "World"
assert_not_contains "String should not contain 'Goodbye'" "$string" "Goodbye"

# Test error handling
test_section "Error Handling"

test_case "Error function behavior"
# Create a function that fails
fail_function() {
    return 1
}

assert_failure "Function should fail" fail_function

# Clean up unit test environment
# (handled automatically by trap set in unit_init)
