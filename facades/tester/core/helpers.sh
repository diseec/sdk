#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST DEFINITION HELPERS                                                 ┃
# ┃ Provides convenient functions for defining tests with "only" support   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Helper function to mark a test as "only"
# Usage: test_my_test_only() { ... }
# This function will be automatically registered as an "only" test
_sdk_tester_mark_test_only() {
    local function_name="$1"
    
    # Extract the actual test name (remove "_only" suffix)
    local actual_test_name="${function_name%_only}"
    
    # Register as an "only" function
    sdk_tester_registry_register "$actual_test_name" "true"
}

# Alternative: Helper function for explicit only marking
# Usage: only test_my_test() { ... }
only() {
    local function_name="$1"
    
    # Register as an "only" function
    sdk_tester_registry_register "$function_name" "true"
    
    # Return the function name so it can be used normally
    echo "$function_name"
}

# Helper to define a test that should be skipped
# Usage: skip test_my_test() { ... } or test_my_test_skip() { ... }
skip() {
    local function_name="$1"
    
    # For now, we'll just not register skipped tests
    # In the future, this could be enhanced to show skipped tests in output
    # Register as a regular function but mark it as skipped
    sdk_tester_registry_register "${function_name}_skipped" "false"
    
    # Return a no-op function name
    echo "_sdk_tester_skipped_test"
}

# No-op function for skipped tests
_sdk_tester_skipped_test() {
    skip_test "Test was marked as skipped"
}

# Advanced: Helper to define test groups (for future enhancement)
describe() {
    local group_name="$1"
    shift
    
    # For now, this is just a documentation helper
    # In the future, this could be used for grouping and filtering
    echo "# Test group: $group_name"
    
    # Execute the test definitions in the group
    "$@"
}

# Helper to create a test function with automatic registration
# This provides an alternative syntax for defining tests
it() {
    local test_description="$1"
    local test_function="$2"
    
    # Convert description to function name
    local function_name
    function_name="test_$(echo "$test_description" | tr ' ' '_' | tr -cd '[:alnum:]_')"
    
    # Register the test
    sdk_tester_registry_register "$function_name" "false"
    
    # Define the function dynamically
    eval "$function_name() { $test_function; }"
}

# Helper for "only" version of it()
it_only() {
    local test_description="$1"
    local test_function="$2"
    
    # Convert description to function name
    local function_name
    function_name="test_$(echo "$test_description" | tr ' ' '_' | tr -cd '[:alnum:]_')"
    
    # Register as "only" test
    sdk_tester_registry_register "$function_name" "true"
    
    # Define the function dynamically
    eval "$function_name() { $test_function; }"
}
