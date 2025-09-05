#!/usr/bin/env bash
# Advanced E2E test for SDK CLI workflow scenarios

# Import required libraries
export D_SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TESTER_LIB_DIR="$D_SDK_DIR/lib/tester"
source "$TESTER_LIB_DIR/e2e_core.sh"
source "$D_SDK_DIR/tests/e2e/helpers/common.sh"

# Setup a complete test project environment
e2e_setup_scenario "workflow-tests"
project_dir=$(e2e_setup_test_project "workflow-project")
cd "$project_dir"

# Initialize git repository for the project
git init --quiet
git config user.name "E2E Test"
git config user.email "e2e-test@example.com"
git add .
git commit -m "Initial commit" --quiet

# Test a complex workflow scenario
test_section "Project Workflow Scenario"

test_case "Project status should report correctly"
e2e_assert_command_success "Status command should succeed" status
e2e_assert_output_contains "Status should mention configuration" "config" "stdout"
e2e_assert_output_contains "Status should check dependencies" "dependencies" "stdout"

test_case "Project development environment should parse correctly"
# Just test parsing to avoid actual Docker operations
e2e_assert_command_success "Develop command should parse correctly" develop --dry-run
e2e_assert_output_contains "Output should mention docker compose" "compose" "stdout"

test_case "Help command after docker should work"
# Test multiple commands in sequence
e2e_assert_command_success "Docker help should succeed" docker help
e2e_assert_output_contains "Docker help should show commands" "Docker" "stdout"

e2e_assert_command_success "Help command should succeed after other commands" help
e2e_assert_output_contains "Help should show all commands" "commands" "stdout"

# Test chained/dependent commands
test_section "Command Chaining and Dependencies"

test_case "Configuration and status commands should work together"
# First check config
e2e_assert_command_success "Config summary should succeed" config summary
# Then check status which also runs config
e2e_assert_command_success "Status should succeed after config" status
e2e_assert_output_contains "Status should still show config info" "config" "stdout"

# Test environment variables
test_section "Environment Variables Handling"

test_case "Envs command should export environment variables"
e2e_assert_command_success "Envs command should succeed" envs
e2e_assert_output_contains "Envs should export SDK variables" "export" "stdout"
e2e_assert_output_contains "D_SDK_DIR should be set" "D_SDK_DIR" "stdout"

# Test configuration handling
test_section "Configuration Management"

test_case "Config command should handle JSON configuration"
# Create a test config file
echo '{"testKey": "testValue", "nested": {"key": "value"}}' > .config.json

e2e_assert_command_success "Config get should succeed" config get testKey
e2e_assert_output_contains "Config get should return the value" "testValue" "stdout"

# Exit with appropriate code
if [ $FAILED_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
