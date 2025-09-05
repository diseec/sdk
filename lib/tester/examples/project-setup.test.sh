#!/bin/bash

# TEST: Project Setup Example
# DESCRIPTION: Demonstrates creating and testing a temporary project

# Source testing framework
source_once "$D_SDK_DIR/lib/tester/index.sh"

# Create a temporary test project
sdk_lib_tester_utils_section "Project Setup"

temp_project=$(sdk_lib_tester_create_temp_project)

if [[ $? -ne 0 ]]; then
  logit -e "Failed to create temporary project"
  exit 1
fi

logit -o "Created temporary project: $temp_project"

# Test the project setup
project_dir="$D_CTX_DIR/test-projects/$temp_project"

assert_dir_exists "$project_dir" "Project directory should exist"
assert_file_exists "$project_dir/package.json" "package.json should exist"
assert_file_exists "$project_dir/cli" "cli file should exist"

# Test running a command in the project
sdk_lib_tester_utils_section "Project Commands"

output=$(sdk_lib_tester_run_in_project "$temp_project" "./cli hello")
assert_equal "$output" "Hello from test project!" "CLI hello command should work"

# Check if the SDK is correctly linked
sdk_lib_tester_utils_section "SDK Integration"

assert_success "sdk_lib_tester_run_in_project '$temp_project' './cli --version'" "CLI version command should work"

# Clean up the temporary project
sdk_lib_tester_cleanup_temp_project "$temp_project"

assert_false "[[ -d '$project_dir' ]]" "Project directory should be cleaned up"

logit -o "Successfully tested project setup and cleanup"

exit $(( SDK_TESTER_ASSERT_FAILED > 0 ? 1 : 0 ))
