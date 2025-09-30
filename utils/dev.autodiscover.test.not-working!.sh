#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ SDK DEVELOPMENT SERVER TESTS                                            ┃
# ┃ Unit tests for the SDK development server functionality                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Mock environment variables and functions
setup_suite() {
    # Create test workspace structure
    create_test_dir "$TEST_CTX/workspace"
    create_test_dir "$TEST_CTX/workspace/.git"
    create_test_dir "$TEST_CTX/workspace/packages/sdk"
    create_test_dir "$TEST_CTX/workspace/services/app1"
    create_test_dir "$TEST_CTX/workspace/services/app2" 
    
    # Create package.json files
    create_test_file "$TEST_CTX/workspace/package.json" '{
        "name": "root",
        "dependencies": {
            "@diseec/sdk": "^1.0.0"
        }
    }'
    
    create_test_file "$TEST_CTX/workspace/services/app1/package.json" '{
        "name": "app1",
        "dependencies": {
            "@diseec/sdk": "^1.0.0"
        }
    }'
    
    create_test_file "$TEST_CTX/workspace/services/app2/package.json" '{
        "name": "app2",
        "dependencies": {
            "other-package": "^1.0.0"
        }
    }'

    # Export test environment
    export D_SDK_DIR="$TEST_CTX/workspace/packages/sdk"
    export TEST_ROOT="$TEST_CTX/workspace"
}

# Reset environment before each test
setup_test() {
    # Mock command availability
    MOCK_COMMANDS=()
    
    # Create mock command function
    command() {
        local cmd="$1"
        if [[ " ${MOCK_COMMANDS[@]} " =~ " $cmd " ]]; then
            return 0
        fi
        command -v "$cmd" >/dev/null 2>&1
    }
}

# Test git root finding
test_find_git_root() {
    local result
    result=$(find_git_root "$D_SDK_DIR")
    
    assert_equals "$TEST_CTX/workspace" "$result" "Should find the correct git root"
    
    # Test with non-git directory
    result=$(find_git_root "/tmp")
    assert_equals "1" "$?" "Should return error for non-git directory"
}

# Test target path discovery
test_find_target_paths() {
    # Create some node_modules directories
    create_test_dir "$TEST_CTX/workspace/node_modules/@diseec/sdk"
    create_test_dir "$TEST_CTX/workspace/services/app1/node_modules/@diseec/sdk"
    
    local result
    result=$(find_target_paths)
    
    # Should find both paths
    assert_contains "$result" "$TEST_CTX/workspace/node_modules/@diseec/sdk" "Should find root sdk path"
    assert_contains "$result" "$TEST_CTX/workspace/services/app1/node_modules/@diseec/sdk" "Should find app1 sdk path"
    assert_not_contains "$result" "$TEST_CTX/workspace/services/app2/node_modules/@diseec/sdk" "Should not find app2 sdk path"
}

# Test fswatch detection
test_fswatch_detection() {
    # Mock fswatch availability
    MOCK_COMMANDS=(fswatch)
    
    # Test with fswatch available
    if command -v fswatch >/dev/null 2>&1; then
        assert_equals "true" "$USE_FSWATCH" "Should enable fswatch when available"
    else
        assert_equals "false" "$USE_FSWATCH" "Should disable fswatch when not available"
    fi
}

# Test parallel detection
test_parallel_detection() {
    # Mock parallel availability
    MOCK_COMMANDS=(parallel)
    
    # Test with parallel available
    if command -v parallel >/dev/null 2>&1; then
        assert_equals "true" "$USE_PARALLEL" "Should enable parallel when available"
    else
        assert_equals "false" "$USE_PARALLEL" "Should disable parallel when not available"
    fi
}

# Test sync functionality
test_sync_files() {
    # Create source content
    create_test_file "$D_SDK_DIR/test.js" "console.log('test');"
    
    # Create target paths
    local target1="$TEST_CTX/workspace/node_modules/@diseec/sdk"
    local target2="$TEST_CTX/workspace/services/app1/node_modules/@diseec/sdk"
    
    create_test_dir "$target1"
    create_test_dir "$target2"
    
    # Mock target paths
    TARGET_PATHS=("$target1" "$target2")
    
    # Test sync
    sync_files
    
    # Verify sync results
    assert_file_exists "$target1/test.js" "Should sync file to first target"
    assert_file_exists "$target2/test.js" "Should sync file to second target"
    assert_equals "console.log('test');" "$(cat "$target1/test.js")" "Should sync correct content"
}

# Test checksum generation
test_get_checksum() {
    # Create test files
    create_test_file "$D_SDK_DIR/file1.js" "content1"
    create_test_file "$D_SDK_DIR/file2.js" "content2"
    
    local checksum1
    local checksum2
    
    checksum1=$(get_checksum)
    assert_not_empty "$checksum1" "Should generate non-empty checksum"
    
    # Modify a file
    create_test_file "$D_SDK_DIR/file1.js" "modified"
    
    checksum2=$(get_checksum)
    assert_not_equals "$checksum1" "$checksum2" "Checksum should change when files change"
}

# Test cleanup
test_cleanup() {
    # Create a background process
    sleep 100 &
    local pid=$!
    
    # Run cleanup
    cleanup
    
    # Check if process was killed
    if ps -p $pid > /dev/null; then
        fail "Background process should be killed"
    fi
}

# Test display functions
test_display_status() {
    # Set up test state
    SYNC_COUNT=5
    START_TIME=$(($(date +%s) - 3600))  # 1 hour ago
    STATUS_LINE_ACTIVE=true
    
    # Capture status output
    local output
    output=$(display_status)
    
    assert_contains "$output" "Uptime:" "Should show uptime"
    assert_contains "$output" "Syncs: 5" "Should show correct sync count"
}