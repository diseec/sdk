#!/bin/bash

# Focusing on edge cases, CI issues, and hanging prevention

# Test stdin function
test_stdin_basic_input() {
    # Test basic input
    export D_GLOB_TTY="false"  # Non-TTY mode for testing
    
    # Initialize the variable
    test_var=""
    
    # Simulate input using here string (<<<) instead of pipe (|)
    stdin test_var "Enter value:" <<< "test input"
    
    assert_equals "test input" "$test_var" "stdin should store input in the specified variable"
}

test_stdin_default_value() {
    # Test default value
    export D_GLOB_TTY="false"  # Non-TTY mode for testing
    
    # Initialize the variable
    local test_var=""
    
    # Simulate empty input (just press Enter)
    stdin test_var "Enter value:" --default="default value" <<< ""
    
    assert_equals "default value" "$test_var" "stdin should use default value when input is empty"
}

test_stdin_validation_success() {
    # Test input validation - success case
    export D_GLOB_TTY="false"  # Non-TTY mode for testing
    
    # Initialize the variable
    local test_var=""
    
    # Simulate valid input
    stdin test_var "Enter number:" --validate="^[0-9]+$" --error="Numbers only" <<< "123"
    
    assert_equals "123" "$test_var" "stdin should accept valid input"
}

test_stdin_optional_input() {
    # Test optional input
    export D_GLOB_TTY="false"  # Non-TTY mode for testing
    
    # Initialize the variable
    local test_var=""
    
    # Simulate empty input for optional field
    stdin test_var "Enter optional:" --optional <<< ""
    
    assert_equals "" "$test_var" "stdin should allow empty input for optional fields"
}

test_stdin_non_tty_timeout() {
    # Test that stdin doesn't hang in non-TTY mode
    export D_GLOB_TTY="false"
    
    # Set up a timeout command
    local test_var=""
    
    stdin test_var 'Enter value:' <<< "test input"
    assert_equals "test input" "$test_var" "stdin should process input in non-TTY mode"
}

test_stdin_signal_handling() {
    # Test that stdin properly handles interrupt signals
    export D_GLOB_TTY="true"
    local test_var=""
    
    # Send SIGINT after 1 second
    (sleep 1; kill -INT $$) &
    
    # stdin test_var 'Enter value:' <<< "test input" 2>/dev/null

    # Attempt to read input
    if stdin test_var "Enter value:" 2>/dev/null; then
        stdout -e "stdin should exit on SIGINT"
    fi
    
    wait # Clean up background process
}

test_stdin_multiple_validations() {
    # Test complex validation scenarios
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Test valid input
    stdin test_var "Enter value:" --validate="^[a-z]+[0-9]+$" --error="Invalid format" <<< "valid123"
    assert_equals "valid123" "$test_var" "stdin should accept valid input"
    
    # Test invalid input with default fallback
    stdin test_var "Enter value:" --validate="^[a-z]+[0-9]+$" --default="fallback123" --error="Invalid format" <<< ""
    assert_equals "fallback123" "$test_var" "stdin should use default on invalid input"
}

test_stdin_hidden_input() {
    # Test hidden input mode
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Test hidden input with validation
    stdin test_var "Enter password:" --hidden --validate="^.{8,}$" --error="Password too short" <<< "secretpass123"
    assert_equals "secretpass123" "$test_var" "stdin should handle hidden input with validation"
}

test_stdin_empty_handling() {
    # Test various empty input scenarios
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Test empty input with optional flag
    stdin test_var "Enter optional:" --optional <<< ""
    assert_equals "" "$test_var" "stdin should allow empty input when optional"
    
    # Test empty input with default
    stdin test_var "Enter value:" --default="default_value" <<< ""
    assert_equals "default_value" "$test_var" "stdin should use default on empty input"
}

test_stdin_subshell_execution() {
    # Test stdin behavior in subshell execution contexts
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Test basic subshell execution
    local stdout_result
    local stderr_result
    
    # Capture both stdout and stderr separately
    # stdout_result=$($(stdin test_var "Enter value:" --default="subshell_default") 2>/dev/null)
    stderr_result=$(stdin test_var "Enter value:" --default="subshell_default" 2>&1 >/dev/null)
    
    # # Verify stdout doesn't contain the prompt
    # assert_not_contains "$stdout_result" "Enter value" "stdin should not have question log in stdout"
    
    # Verify stderr contains the prompt
    assert_contains "$stderr_result" "Enter value" "stdin should have question log in stderr"

    # Test subshell with pipe
    echo "piped input" | (
        stdin test_var "Enter value:" --default="pipe_default"
        assert_equals "piped input" "$test_var" "stdin should handle piped input in subshell"
    )
    
    # Test nested subshell execution with TMOUT
    local nested_result
    TMOUT=5 nested_result=$(
        stdin test_var "Enter value:" --default="nested_default" <<< ""
        echo "$test_var"
    )
    assert_equals "nested_default" "$nested_result" "stdin should work in nested subshell execution"
}

test_stdin_radio_type() {
    # Test radio button input type
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Simulate selecting option 2 from radio buttons
    stdin test_var "Select color:" --type="radio" --options="Red,Green,Blue" <<< "2"
    assert_equals "Green" "$test_var" "stdin should return the selected radio option"
    
    # Test default value with radio buttons
    stdin test_var "Select color:" --type="radio" --options="Red,Green,Blue" --default="Blue" <<< ""
    assert_equals "Blue" "$test_var" "stdin should use default value for radio buttons"
    
    # # Test invalid selection with default fallback
    # local stderr_output
    # stderr_output=$(stdin test_var "Select color:" --type="radio" --options="Red,Green,Blue" --default="Red" <<< "4" 2>&1)
    # assert_equals "Red" "$test_var" "stdin should use default on invalid radio selection"
}

test_stdin_select_type() {
    # Test select/dropdown input type
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Simulate selecting option 3 from dropdown
    stdin test_var "Select OS:" --type="select" --options="Linux,macOS,Windows" <<< "3"
    assert_equals "Windows" "$test_var" "stdin should return the selected dropdown option"
    
    # Test default value with dropdown
    stdin test_var "Select OS:" --type="select" --options="Linux,macOS,Windows" --default="Linux" <<< ""
    assert_equals "Linux" "$test_var" "stdin should use default value for dropdown"
    
    # Test complex options with spaces and special characters
    stdin test_var "Select item:" --type="select" --options="Option A,Option B,Option C" <<< "2"
    assert_equals "Option B" "$test_var" "stdin should handle options with spaces"
}

test_stdin_type_validation() {
    # Test input type validation
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Test radio buttons with validation
    stdin test_var "Select color:" --type="radio" --options="Red,Green,Blue" \
          --validate="^(Red|Blue)$" --default="Red" --error="Must be Red or Blue" <<< "2"
    assert_equals "Red" "$test_var" "stdin should validate radio button selections"
}

test_stdin_complex_options() {
    # Test complex options with multiple dashes and special patterns
    export D_GLOB_TTY="false"
    local test_var=""
    
    # Test options similar to the issue pattern with dashes and complex names
    stdin test_var "Select submodule:" --type="select" --optional \
          --options="test-submodule,submodule1,submodule2,submodule3,duplicate-submodule,scope-test-submodule" <<< "1"
    assert_equals "test-submodule" "$test_var" "stdin should handle options with dashes"
    
    # Test selecting a different option from the complex list
    stdin test_var "Select submodule:" --type="select" \
          --options="test-submodule,submodule1,submodule2,submodule3,duplicate-submodule,scope-test-submodule" <<< "5"
    assert_equals "duplicate-submodule" "$test_var" "stdin should handle selection from complex options list"

    stdin test_var "Select submodule:" --type="select" \
          --options="test-submodule,submodule1,submodule2,submodule3,duplicate-submodule,scope-test-submodule" <<< "1,2"
    assert_equals "test-submodule,submodule1" "$test_var" "stdin should handle selection from complex options list"
}


# TODO add all and none for selection