#!/bin/bash
# Test utility functions

# Print an info message during tests
test_info() {
    local message="$1"
    echo -e "  ${COLOR_INFO}ℹ${NC} $message"
}

# Print a warning during tests
test_warn() {
    local message="$1"
    echo -e "  ${COLOR_WARNING}⚠${NC} $message"
}

# Print an error message during tests
test_error() {
    local message="$1"
    echo -e "  ${COLOR_ERROR}✗${NC} $message"
}

# Skip a test with a reason
test_skip() {
    local reason="$1"
    echo -e "  ${COLOR_WARNING}⊘ SKIPPED:${NC} $reason"
}

# Source a module with error handling
source_module() {
    local module_path="$1"
    # local description="${2:-$module_path}"
    
    if [ -f "$module_path" ]; then
        if source "$module_path" 2>/dev/null; then
            # test_info "Loaded $module_path"
            return 0
        else
            test_error "Failed to source $module_path"
            return 1
        fi
    else
        test_warn "$module_path not found"
        return 1
    fi
}

# Create a temporary file for testing
create_temp_file() {
    local content="${1:-}"
    local temp_file=$(mktemp)
    if [ -n "$content" ]; then
        echo "$content" > "$temp_file"
    fi
    echo "$temp_file"
}

# Create a temporary directory for testing
create_temp_dir() {
    mktemp -d
}

# Clean up temporary files and directories
cleanup_temp() {
    local path="$1"
    if [[ "$path" == /tmp/* ]] || [[ "$path" == /var/folders/* ]]; then
        rm -rf "$path"
    else
        test_warn "Refusing to clean up path outside temp directory: $path"
    fi
}

# Run a command and capture its output
run_and_capture() {
    local output_var="$1"
    local error_var="$2"
    shift 2
    
    local temp_out=$(mktemp)
    local temp_err=$(mktemp)
    
    if "$@" >"$temp_out" 2>"$temp_err"; then
        local exit_code=0
    else
        local exit_code=$?
    fi
    
    if [ -n "$output_var" ]; then
        eval "$output_var=\"$(cat "$temp_out")\""
    fi
    
    if [ -n "$error_var" ]; then
        eval "$error_var=\"$(cat "$temp_err")\""
    fi
    
    rm -f "$temp_out" "$temp_err"
    return $exit_code
}

# Measure execution time of a command
time_command() {
    local description="$1"
    shift
    
    local start_time=$(date +%s%N)
    "$@"
    local exit_code=$?
    local end_time=$(date +%s%N)
    
    local duration_ns=$((end_time - start_time))
    local duration_ms=$((duration_ns / 1000000))
    
    test_info "$description took ${duration_ms}ms"
    return $exit_code
}

# Setup test environment
setup_test_env() {
    # Create a temporary directory for test artifacts
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_ORIGINAL_PWD=$(pwd)
    
    # Set up cleanup trap
    trap 'cleanup_test_env' EXIT
}

# Cleanup test environment
cleanup_test_env() {
    # Return to original directory
    if [ -n "${TEST_ORIGINAL_PWD:-}" ]; then
        cd "$TEST_ORIGINAL_PWD" 2>/dev/null || true
    fi
    
    # Clean up temp directory
    if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

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
}

# Restore original command after mocking
restore_command() {
    local command_name="$1"
    local mock_script="$TEST_TEMP_DIR/mock_$command_name"
    
    if [ -f "$mock_script" ]; then
        rm -f "$mock_script"
    fi
}

# Export utility functions
export -f test_info test_warn test_error test_skip source_module
export -f create_temp_file create_temp_dir cleanup_temp
export -f run_and_capture time_command
export -f setup_test_env cleanup_test_env
export -f mock_command restore_command
