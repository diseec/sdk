#!/bin/bash
# Unit testing framework
# This script provides helpers specifically for unit testing

# Unit test initialization
unit_init() {
    # Set up unit test environment
    test_info "Initializing unit test environment"
    
    # Set default test timeout
    export TEST_TIMEOUT_SECONDS=${TEST_TIMEOUT_SECONDS:-60}
    
    # Create isolated environment
    export UNIT_TEST_TEMP_DIR=$(mktemp -d)
    export ORIGINAL_PATH="$PATH"
    
    # Clean up on exit
    trap unit_cleanup EXIT
}

# Unit test cleanup
unit_cleanup() {
    # Restore original PATH
    export PATH="$ORIGINAL_PATH"
    
    # Clean up temp directory
    if [ -n "$UNIT_TEST_TEMP_DIR" ] && [ -d "$UNIT_TEST_TEMP_DIR" ]; then
        rm -rf "$UNIT_TEST_TEMP_DIR"
    fi
    
    test_info "Unit test environment cleaned up"
}

# Mock a shell command with a specific behavior
unit_mock_command() {
    local command="$1"
    local behavior="$2"
    
    mock_command "$command" "$behavior"
}

# Test a shell function in isolation
unit_test_function() {
    local function_name="$1"
    shift
    
    # Check if function exists
    if ! declare -f "$function_name" >/dev/null 2>&1; then
        test_error "Function '$function_name' does not exist"
        return 1
    fi
    
    # Run the function with arguments
    test_info "Testing function: $function_name"
    "$function_name" "$@"
    return $?
}

# Create a temporary test script
unit_create_test_script() {
    local content="$1"
    local temp_script="$UNIT_TEST_TEMP_DIR/test_script.sh"
    
    echo "#!/bin/bash" > "$temp_script"
    echo "$content" >> "$temp_script"
    chmod +x "$temp_script"
    
    echo "$temp_script"
}

# Export unit testing functions
export -f unit_init unit_cleanup unit_mock_command unit_test_function unit_create_test_script
