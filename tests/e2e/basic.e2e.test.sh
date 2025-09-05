#!/usr/bin/env bash
# E2E test for basic SDK CLI commands

# Set up test environment
export D_SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export TESTER_LIB_DIR="$D_SDK_DIR/lib/tester"

# Source E2E testing functions
source "$TESTER_LIB_DIR/core/assertions.sh"
source "$TESTER_LIB_DIR/e2e/functions.sh"

# Initialize E2E test environment
e2e_init

# Test version command
test_section "Version Command"

test_case "SDK version command should return version info"
e2e_assert_success "Version command should succeed" --version
e2e_assert_output_contains "Output should contain SDK name" "sdk" "stdout"
e2e_assert_output_matches "Output should include version number" "v[0-9]+(\.[0-9]+)*" "stdout"

# Test help command
test_section "Help Command"

test_case "SDK help command should display help information"
e2e_assert_success "Help command should succeed" help
e2e_assert_output_contains "Output should contain Usage section" "Usage" "stdout"
e2e_assert_output_contains "Output should list available commands" "commands" "stdout"

# Test invalid command
test_section "Invalid Command Handling"

test_case "SDK should handle invalid commands gracefully"
e2e_assert_failure "Invalid command should fail" "" invalid-command
e2e_assert_output_contains "Output should indicate unknown command" "Unknown command" "stderr"

# Exit with appropriate code
if [ $FAILED_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
