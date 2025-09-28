#!/bin/bash

# Focusing on edge cases, CI issues, and hanging prevention

# Test retry function
test_retry_success_first_attempt() {
    # Test retry with successful command on first attempt
    export D_GLOB_TTY="false"  # Non-TTY mode for testing
    
    # Test basic output capture
    local result1=$(capture_test_log retry --auto "echo 'success'")
    assert_contains "$result1" "success" "retry should return command output"

    local result2=$(capture_test_log retry --auto "echo 'success'")
    assert_equals "success" "$result2" "retry should return command output"

    retry --auto "echo 'success'" output
    assert_equals "success" "$output" "retry should capture command output in variable"
}

test_retry_auto_mode() {
    # Test retry in auto mode with initially failing command
    export D_GLOB_TTY="false"  # Non-TTY mode for testing
    
    # Create a command that fails on first run but succeeds on second
    local test_script="$TEST_CTX/retry_test.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
if [ -f "$TEST_CTX/attempt.txt" ]; then
    echo "success"
    exit 0
else
    touch "$TEST_CTX/attempt.txt"
    echo "failure"
    exit 1
fi
EOF
    chmod +x "$test_script"
    
    local result=$(retry --auto --timeout=1 --max-attempts=3 "$test_script" output)
    
    assert_equals "success" "$output" "retry should eventually capture success output"
}

test_retry_auto_timeout() {
    # Test auto retry with strict timeout
    export D_GLOB_TTY="false"
    
    # Create a command that always fails but takes time
    local test_script="$TEST_CTX/slow_fail.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
sleep 1
exit 1
EOF
    chmod +x "$test_script"
    
    # Run retry with short timeout
    local start_time=$(date +%s)
    retry --auto --timeout=1 --max-attempts=2 "$test_script"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Should take roughly 4 seconds (2 attempts with 1 second timeout each and 1 for the sleep)
    assert_less_than "$duration" "5" "retry should respect timeout between attempts"
}

test_retry_output_capture() {
    # Test output capturing in various scenarios
    export D_GLOB_TTY="false"
    
    # Test successful command output capture
    local output=""
    retry --auto --max-attempts=1 "echo 'success'" output
    assert_equals "success" "$output" "retry should capture successful command output"
    
    # Test failed command output capture
    local error_output=""
    retry --auto --max-attempts=1 "echo 'error message' >&2; exit 1" error_output
    assert_contains "$error_output" "error message" "retry should capture error output"
}

# test_retry_signal_handling() {
#     # Test retry's signal handling
#     export D_GLOB_TTY="false"
    
#     # Create a test script that we know exists and works
#     local test_script="$TEST_CTX/simple_sleep.sh"
#     echo '#!/bin/bash' > "$test_script"
#     echo 'sleep 2' >> "$test_script"
#     chmod 755 "$test_script"
    
#     # Verify the script
#     if [ ! -x "$test_script" ]; then
#         echo "Test script ($test_script) is not executable"
#         ls -l "$test_script"
#         return 1
#     fi
    
#     # First verify the script works
#     if ! "$test_script"; then
#         echo "Test script ($test_script) failed to execute"
#         return 1
#     fi
    
#     # Run retry in foreground (more like real usage) and send SIGINT
#     local start_time=$(date +%s)
    
#     # Run retry in foreground
#     retry --auto --timeout=1 --max-attempts=10 "$test_script" || true
    
#         sleep 2 # Reduced wait time
#         kill -INT $$  # Send to our own process group
    
#     local end_time=$(date +%s)
#     local duration=$((end_time - start_time))
    
#     assert_less_than "$duration" "4" "retry should handle Ctrl+C interruption"
# }

test_retry_mixed_mode() {
    # Test transition from auto to manual mode
    export D_GLOB_TTY="false"
    
    # Create a script that fails a specific number of times
    local test_script="$TEST_CTX/count_fails.sh"
    cat > "$test_script" << 'EOF'
#!/bin/bash
count_file="$TEST_CTX/fail_count.txt"
if [ ! -f "$count_file" ]; then
    echo "0" > "$count_file"
fi
count=$(<"$count_file")
if [ "$count" -lt "5" ]; then
    echo $((count + 1)) > "$count_file"
    exit 1
fi
echo "success"
exit 0
EOF
    chmod +x "$test_script"
    
    # Run retry with mixed mode (should fail after max auto attempts)
    local output=""
    retry --auto --manual --timeout=1 --max-attempts=2 "$test_script" output <<< n
    
    # Should fail as we're in non-TTY mode and manual retry isn't possible
    assert_not_equals "0" "$?" "retry should fail when manual mode isn't possible in non-TTY"
}

test_retry_environment_handling() {
    # Test retry behavior with different environment variables
    export D_GLOB_TTY="false"
    local test_script="$TEST_CTX/env_test.sh"
    
    # Create a script that checks environment preservation
    cat > "$test_script" << 'EOF'
#!/bin/bash
if [ -n "$TEST_ENV_VAR" ]; then
    echo "$TEST_ENV_VAR"
    exit 0
fi
exit 1
EOF
    chmod +x "$test_script"
    
    # Test environment variable preservation
    export TEST_ENV_VAR="test_value"
    local output=""
    retry --auto --max-attempts=1 "$test_script" output
    
    assert_equals "test_value" "$output" "retry should preserve environment variables"
}
