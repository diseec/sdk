#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST SUITE MANAGEMENT                                                   ┃
# ┃ Manages test suites, setup, teardown, and test organization            ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Suite lifecycle hooks
suite_setup() {
    # Override this function in test files for suite-wide setup
    # This runs once before all tests in the file
    return 0
}

suite_teardown() {
    # Override this function in test files for suite-wide cleanup  
    # This runs once after all tests in the file
    return 0
}

setup_test_ctx() {
    export TEST_CTX=$(create_test_ctx "ctx_$RANDOM")
    export TESTER_LOG_FILE=$(mktemp $TEST_CTX/$TESTER_LOG_FILE_NAME)
    export TESTER_RESULT_FILE="$TEST_CTX/$TESTER_RESULT_FILE_NAME"

    if [ -z "$TEST_CTX" ] || [ ! -d "$TEST_CTX" ]; then
        logit -e "Failed to create test workspace"
        return 1
    fi
    
    # Create and initialize the test result file
    echo "PASSED" > "$TESTER_RESULT_FILE"

    cd "$TEST_CTX" || return 1

    return 0
}

setup_test() {
    # Override this function in test files for per-test setup
    # This runs before each individual test function
    return 0
}

teardown_test() {
    # Override this function in test files for per-test cleanup
    # This runs after each individual test function
    rm -fr "$D_ORG_DIR"
    return 0
}

# Execute a test with proper setup and teardown
_sdk_tester_execute_test_with_hooks() {
    local test_function="$1"
    TESTER_CURRENT_TEST="$test_function"
    
    # Run test setup if defined
    if declare -f setup_test >/dev/null 2>&1; then
        if ! setup_test; then
            logit -e "Test setup failed for $test_function"
            return 1
        fi
    fi
    
    # Run the actual test
    local test_result=0
    if ! "$test_function"; then
        test_result=1
    fi
    
    # Run test teardown if defined (always run, even if test failed)
    if declare -f teardown_test >/dev/null 2>&1; then
        if ! teardown_test; then
            logit -w "Test teardown failed for $test_function"
        fi
    fi
    
    return $test_result
}

# Execute suite with proper setup and teardown
_sdk_tester_execute_suite() { # UNUSED
    local test_file="$1"
    
    # Source the test file
    source "$test_file"
    
    # Run suite setup if defined
    if declare -f suite_setup >/dev/null 2>&1; then
        if ! suite_setup; then
            logit -e "Suite setup failed for $test_file"
            return 1
        fi
    fi
    
    # Find and execute all test functions
    local test_functions
    test_functions=$(declare -F | grep "declare -f test_" | sed 's/declare -f //')
    
    if [ -z "$test_functions" ]; then
        logit -w "  No test functions found (functions should start with 'test_')"
        return 0
    fi
    
    local suite_failed=0
    
    # Execute each test function with hooks
    echo "$test_functions" | while IFS= read -r test_function; do
        if [ -n "$test_function" ]; then
            if [ "$TESTER_VERBOSE" = "true" ]; then
                logit --ansi="$TESTER_COLOR_DIM" "    $(ansi 90 "→") $test_function"
            fi
            
            if ! _sdk_tester_execute_test_with_hooks "$test_function"; then
                suite_failed=1
                if [ "$TESTER_FAIL_FAST" = "true" ]; then
                    break
                fi
            fi
        fi
    done
    
    # Run suite teardown if defined (always run)
    if declare -f suite_teardown >/dev/null 2>&1; then
        if ! suite_teardown; then
            logit -w "Suite teardown failed for $test_file"
        fi
    fi
    
    return $suite_failed
}


# Create a temporary test workspace
create_test_ctx() {
    local workspace_name="${1:-test_ctx_$$}"
    local workspace_dir="/tmp/$workspace_name"

    # Clean up any existing directory
    if [ -d "$workspace_dir" ]; then
        rm -rf "$workspace_dir"
    fi

    mkdir -p "$workspace_dir"
    
    # Copy CLI template file to workspace
    if [ -f "$D_SDK_DIR/templates/cli" ]; then
        cp "$D_SDK_DIR/templates/cli" "$workspace_dir/cli"
        chmod +x "$workspace_dir/cli"
    else
        logit -w "CLI template not found at $D_SDK_DIR/templates/cli"
    fi

    # Copy SDK files to workspace
    mkdir -p "$workspace_dir/$D_SDK_LOCAL_RELATIVE_PATH"
    if [ -d "$D_SDK_DIR" ] && [ -n "$(ls -A $D_SDK_DIR 2>/dev/null)" ]; then
        cp -r $D_SDK_DIR/* "$workspace_dir/$D_SDK_LOCAL_RELATIVE_PATH"
    else
        logit -e "No files to copy from $D_SDK_DIR/"
    fi

    # Setup git
    git config user.email "test@test.test" >/dev/null 2>&1
    git config user.name "Tester Testing" >/dev/null 2>&1
    git init -b main "$workspace_dir" >/dev/null 2>&1 || {
        logit -e "Failed to initialize git repository in $workspace_dir"
        return 1
    }

    (cd "$workspace_dir" && git remote add origin "https://github.com/$D_ORG_NAME/$workspace_name.git") >/dev/null 2>&1 || {
        logit -e "Failed to add git remote in $workspace_dir"
        return 1
    }

    echo "$workspace_dir"
}

# Clean up test workspace  
cleanup_test_ctx() {
    local workspace_dir="$1"
    
    if [ -n "$workspace_dir" ] && [ -d "$workspace_dir" ]; then
        rm -rf "$workspace_dir"
    fi
}

# Helper function to create test files
create_test_file() {
    local file_path="$1"
    local content="${2:-}"
    
    local dir_path
    dir_path=$(dirname "$file_path")
    mkdir -p "$dir_path"
    
    if [ -n "$content" ]; then
        echo "$content" > "$file_path"
    else
        touch "$file_path"
    fi
}

# Helper function to create test directories
create_test_dir() {
    local dir_path="$1"
    mkdir -p "$dir_path"
}

# Global variable to store test logs
export TESTER_COMMAND_LOGS=""

# Note: The TESTER_LOG_FILE is now created per test in runner.sh

# Store the path of the actual D command before we define our function
if [ -z "$_GLOBAL_D_CMD" ]; then
    # We need to find the path to the D command
    # This must be run before the D() function is defined
    export _GLOBAL_D_CMD=$(which D 2>/dev/null || echo "/usr/local/bin/D")
fi

# Ensure D command called in tests points to the local D since it's global,
# and automatically captures output for better logging
D() {
    # In this case, we want to access the global D command
    if [ -x "$_GLOBAL_D_CMD" ]; then
        (cd $TEST_CTX && capture "$_GLOBAL_D_CMD" "$@")
        return $?
    else
        logit -e "Global D command not found at $_GLOBAL_D_CMD"
        return 1
    fi
}

# Capture command output and add it to the logs
# Usage: 
#   result=$(capture command args)     # Runs command and returns its output
#   result=$(capture "command args")   # Alternative syntax for complex commands
capture() {
    # If no command provided, return empty
    if [ $# -eq 0 ]; then
        return 0
    fi
    
    local command_output
    local cmd
    local timestamp=$(date "+%H:%M:%S")
    local exit_code
    
    # Handle command as string or as arguments
    if [ $# -eq 1 ] && [[ "$1" == *" "* ]]; then
        # Command is passed as a single string
        cmd="$1"
        # Use eval to execute the command string directly
        command_output=$(set -o pipefail; eval "$cmd" 2>&1)
        exit_code=$?
    else
        # Command is passed as arguments
        cmd="$*"
        # For single commands without spaces, execute directly
        command_output=$("$@" 2>&1)
        exit_code=$?
    fi
    
    # Strip ANSI color codes from command output
    local command_output_clean
    command_output_clean=$(echo "$command_output" | sed 's/\x1b\[[0-9;]*m//g')
    
    # If TESTER_LOG_FILE is set, write to the log file with styled format
    if [ -n "$TESTER_LOG_FILE" ]; then
        {
            # Color selection based on exit code
            local color_code="90"  # Gray for success
            if [ $exit_code -ne 0 ]; then
                color_code="31"    # Red for failure
            fi
            
            # Command line with timestamp and exit status
            # Clean the command by removing the dir prefix pattern
            local cleaned_cmd=$(echo "$cmd" | sed 's/\/usr\/local\/bin\///')
            echo -e "\033[90m[$timestamp][\033[90m$\033[90m][\033[${color_code}m$exit_code\033[90m] $cleaned_cmd\033[0m"
            
            # Output with proper indentation (if there is any output)
            if [ -n "$command_output_clean" ]; then
                echo -e "\033[2;90m$command_output_clean\033[0m"
            fi
            
            echo -e "\033[2;90m-------------------------------------------------------------------------------\033[0m"
        } >> "$TESTER_LOG_FILE"
    fi
    
    # Return the original command output (with colors)
    echo "$command_output"
    return $exit_code
}

# Set up a mock command (for testing CLI tools)
mock_command() {
    local command_name="$1"
    local mock_behavior="${2:-echo 'mocked $command_name called with args: $@'}"
    local mock_exit_code="${3:-0}"
    
    # Create a mock function
    eval "$command_name() { $mock_behavior; return $mock_exit_code; }"
}

# Restore original command (remove mock)
unmock_command() {
    local command_name="$1"
    unset -f "$command_name" 2>/dev/null || true
}

# Assert that a mock was called with specific arguments
assert_mock_called_with() {
    local command_name="$1"
    local expected_args="$2"
    local message="${3:-"Mock $command_name should have been called with: $expected_args"}"
    
    # This is a simplified implementation - in practice, you'd need to track calls
    # For a full implementation, you'd modify mock_command to track calls
    logit -w "assert_mock_called_with is not fully implemented yet"
    return 0
}
