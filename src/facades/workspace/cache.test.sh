#!/bin/bash
# Test script for workspace cache functions

# Source the workspace module
source_module "$KIT_SRC_DIR/facades/workspace/index.sh"

test_section "Workspace Cache Functions"

# Test 1: Check if cache functions are loaded
test_case "Cache Function Availability"
assert_function_exists "fac_wor_get_cache_dir function exists" "fac_wor_get_cache_dir"
assert_function_exists "fac_wor_get_cache_subdir function exists" "fac_wor_get_cache_subdir"

# Test 2: Test cache directory creation
test_case "Cache Directory Creation"
cache_dir=$(fac_wor_get_cache_dir)
assert_not_empty "Cache dir path is not empty" "$cache_dir"
assert_contains "Cache dir path contains .cache" "$cache_dir" ".cache"

if [ -d "$cache_dir" ]; then
    assert_success "Cache directory exists" true
else 
    assert_failure "Cache directory should exist" true
fi

# Test 3: Test cache subdirectory creation
test_case "Cache Subdirectory Creation"
test_subdir="test_subdir"
cache_subdir=$(fac_wor_get_cache_subdir "$test_subdir")
assert_not_empty "Cache subdir path is not empty" "$cache_subdir"
assert_contains "Cache subdir path contains test_subdir" "$cache_subdir" "$test_subdir"

if [ -d "$cache_subdir" ]; then
    assert_success "Cache subdirectory exists" true
else 
    assert_failure "Cache subdirectory should exist" true
fi

# Cleanup test subdirectory
if [ -d "$cache_subdir" ]; then
    rmdir "$cache_subdir" 2>/dev/null || true
fi

test_section "Workspace Cache Tests Complete"
