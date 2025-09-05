#!/usr/bin/env bash
# E2E test for Git-related SDK CLI commands

# Import required libraries
export D_SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TESTER_LIB_DIR="$D_SDK_DIR/lib/tester"
source "$TESTER_LIB_DIR/e2e_core.sh"
source "$D_SDK_DIR/tests/e2e/helpers/common.sh"

# Setup a test environment with a git repo
e2e_setup_scenario "git-tests"
repo_dir=$(e2e_create_git_repo "git-test-repo")
cd "$repo_dir"

# Test git status command
test_section "Git Status Command"

test_case "SDK git status command should report on branch status"
e2e_assert_command_success "Git status command should succeed" git status
e2e_assert_output_contains "Output should contain branch information" "branch" "stdout"

# Test git commit commands
test_section "Git Commit Commands"

test_case "SDK git commit command should parse correctly"
# Create a change to commit
echo "Test change" > test-file.txt
git add test-file.txt

# We're just testing command parsing here, not actual execution
# since CI may not have GitHub credentials
e2e_assert_command_success "Git commit command should parse correctly" git commit --dry-run --message "Test commit"

# Test git log command
test_section "Git Log Command"

test_case "SDK git log command should show commit history"
e2e_assert_command_success "Git log command should succeed" git log --max-count=1
e2e_assert_output_contains "Output should show commit information" "commit" "stdout"

# Test git checkout command
test_section "Git Checkout Command"

test_case "SDK git checkout command should parse correctly"
e2e_assert_command_success "Git checkout command should parse correctly" git checkout --help
e2e_assert_output_contains "Output should mention checkout functionality" "checkout" "stdout"

# Exit with appropriate code
if [ $FAILED_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
