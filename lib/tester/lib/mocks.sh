#!/bin/bash
# Mocking utilities for testing

# Mock a command for testing
mock_command() {
    local command_name="$1"
    local mock_behavior="$2"
    
    # Create a temporary script that implements the mock
    local mock_script="$TEST_TEMP_DIR/mock_$command_name"
    echo "#!/bin/bash" > "$mock_script"
    echo "$mock_behavior" >> "$mock_script"
    chmod +x "$mock_script"
    
    # Add to PATH
    export PATH="$TEST_TEMP_DIR:$PATH"
    
    test_info "Created mock for command: $command_name"
}

# Restore original command after mocking
restore_command() {
    local command_name="$1"
    local mock_script="$TEST_TEMP_DIR/mock_$command_name"
    
    if [ -f "$mock_script" ]; then
        rm -f "$mock_script"
        test_info "Removed mock for command: $command_name"
    fi
}

# Mock a function for testing
mock_function() {
    local function_name="$1"
    local mock_behavior="$2"
    
    # Create a new function definition that overrides the original
    eval "$function_name() {
        $mock_behavior
    }"
    
    test_info "Created mock for function: $function_name"
}

# Restore original function after mocking
restore_function() {
    local function_name="$1"
    local original_function="${function_name}_original"
    
    if declare -f "$original_function" >/dev/null 2>&1; then
        # Restore original function if backup exists
        eval "$function_name() {
            $(declare -f "$original_function" | sed "1d" | head -n -1)
        }"
        unset -f "$original_function"
        test_info "Restored original function: $function_name"
    else
        # Just unset the mocked function
        unset -f "$function_name"
        test_info "Removed mock for function: $function_name"
    fi
}

# Create a mock environment variable
mock_env() {
    local var_name="$1"
    local var_value="$2"
    
    # Save original value if it exists
    if [ -n "${!var_name+x}" ]; then
        export "${var_name}_original"="${!var_name}"
    fi
    
    # Set new value
    export "$var_name"="$var_value"
    
    test_info "Created mock for environment variable: $var_name"
}

# Restore original environment variable
restore_env() {
    local var_name="$1"
    local original_var="${var_name}_original"
    
    if [ -n "${!original_var+x}" ]; then
        # Restore original value
        export "$var_name"="${!original_var}"
        unset "$original_var"
    else
        # Unset the variable if there was no original
        unset "$var_name"
    fi
    
    test_info "Restored environment variable: $var_name"
}

# Export mocking functions
export -f mock_command restore_command
export -f mock_function restore_function
export -f mock_env restore_env
