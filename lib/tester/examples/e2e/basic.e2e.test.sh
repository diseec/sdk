#!/bin/bash
# Example E2E test for SDK CLI commands

# Source the E2E testing framework
source "$D_SDK_DIR/lib/testing/frameworks/e2e/framework.sh"

# Initialize E2E test environment
e2e_init

# Set up a test project with SDK installed
e2e_setup_test_project "sdk-test"

# Test basic CLI commands
test_section "Basic CLI Commands"

test_case "Version command"
e2e_run_command "$D_CLI_GLOBAL_NAME --version"
e2e_assert_success "Version command should succeed"
e2e_assert_output_contains "Output should contain version information" "v"

test_case "Help command"
e2e_run_command "$D_CLI_GLOBAL_NAME help"
e2e_assert_success "Help command should succeed"
e2e_assert_output_contains "Output should contain usage information" "Usage"
e2e_assert_output_contains "Output should list available commands" "commands"

# Test custom project command
test_section "Custom Project Commands"

test_case "Custom command"
e2e_run_command "$D_CLI_GLOBAL_NAME custom"
e2e_assert_success "Custom command should succeed"
e2e_assert_output_contains "Output should contain custom message" "Custom command"

# Test invalid command handling
test_section "Error Handling"

test_case "Invalid command"
e2e_run_command "$D_CLI_GLOBAL_NAME invalid-command"
e2e_assert_failure "Invalid command should fail"
e2e_assert_output_contains "Output should indicate unknown command" "Unknown command" "stderr"

# Clean up E2E test environment
# (handled automatically by trap set in e2e_init)
