#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST FILE FOR version.sh                                                ┃
# ┃ Tests the functionality of the sdk_cmd_opt_version command              ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Test functions must start with "test_"

test_version_output_format() {    
    # Run the version command and capture output
    local version_output
    
    version_output=$(D --version)

    # Test that output contains expected elements
    assert_not_empty "$version_output" "Version output should not be empty"
    assert_contains "$version_output" "D-SDK Version" "Output should contain D-SDK Version"
    assert_contains "$version_output" "D-CLI Version" "Output should contain D-CLI Version"
    assert_contains "$version_output" "Build" "Output should contain Build label"
    assert_contains "$version_output" "D-SRC" "Output should contain D-SRC label"
    assert_contains "$version_output" "D-CTX" "Output should contain D-CTX label"
}
