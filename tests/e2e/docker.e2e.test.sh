#!/usr/bin/env bash
# E2E test for Docker-related SDK CLI commands

# Import required libraries
export D_SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TESTER_LIB_DIR="$D_SDK_DIR/lib/tester"
source "$TESTER_LIB_DIR/e2e_core.sh"
source "$D_SDK_DIR/tests/e2e/helpers/common.sh"

# Setup a test environment
e2e_setup_scenario "docker-tests"
project_dir=$(e2e_setup_test_project "docker-project")
cd "$project_dir"

# Test docker commands
test_section "Docker Commands"

# Test docker compose command
test_case "SDK docker compose command should parse and validate compose files"
e2e_assert_command_success "Docker compose command should succeed" docker compose config
e2e_assert_output_contains "Output should contain service name" "test-service" "stdout"

# Test docker build command (using alias)
test_case "SDK build command (docker compose build) should work"
# Here we're just checking if the command parses correctly, not actually building
e2e_assert_command_success "Docker build command should parse correctly" build --dry-run

# Test docker execution command
test_case "SDK execute command should parse correctly"
e2e_assert_command_success "Execute command should parse correctly" execute --help
e2e_assert_output_contains "Output should mention execution" "execute" "stdout"

# Test docker system prune (using alias)
test_case "SDK prune command should work"
# Only testing the command parsing, not actual execution
e2e_assert_command_success "Prune command should parse correctly" prune --dry-run

# Exit with appropriate code
if [ $FAILED_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
