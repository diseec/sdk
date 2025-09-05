#!/bin/bash

# Core utilities for the testing framework
# This script provides utility functions for discovering and running tests

# Prevent multiple sourcing
if [[ "${SDK_LIB_TESTER_UTILS_SOURCED:-}" == "1" ]]; then
  return 0
fi
SDK_LIB_TESTER_UTILS_SOURCED=1

# Discover all test files in the project
sdk_lib_tester_utils_discover_tests() {
  if [[ -z "${D_CTX_DIR:-}" ]]; then
    logit -e "D_CTX_DIR is not set"
    return 1
  fi
  
  # Find all test files ending with .test.sh
  find "$D_CTX_DIR" -type f -name "*.test.sh" | sort
}

# Get the name of a test from its file
sdk_lib_tester_utils_get_test_name() {
  local test_file="$1"
  
  # Extract name from first line that starts with # TEST:
  local test_name=$(grep -m 1 "^# TEST:" "$test_file" | sed 's/^# TEST:\s*//')
  
  # If no name is found, use the filename
  if [[ -z "$test_name" ]]; then
    test_name=$(basename "$test_file" .test.sh)
  fi
  
  echo "$test_name"
}

# Get the description of a test from its file
sdk_lib_tester_utils_get_test_description() {
  local test_file="$1"
  
  # Extract description from first line that starts with # DESCRIPTION:
  grep -m 1 "^# DESCRIPTION:" "$test_file" | sed 's/^# DESCRIPTION:\s*//'
}

# Run a single test file
sdk_lib_tester_utils_run_test_file() {
  local test_file="$1"
  local summary_only="${2:-0}"
  
  # Get test name and description
  local test_name=$(sdk_lib_tester_utils_get_test_name "$test_file")
  local test_description=$(sdk_lib_tester_utils_get_test_description "$test_file")
  local relative_path="${test_file#$D_CTX_DIR/}"
  
  # Create a temporary directory for this test
  local test_tmp_dir=$(mktemp -d)
  local test_output_file="$test_tmp_dir/output.log"
  local test_start_time=$(date +%s)
  
  # Set up test environment variables
  export SDK_TEST_FILE="$test_file"
  export SDK_TEST_NAME="$test_name"
  export SDK_TEST_TMP_DIR="$test_tmp_dir"
  
  # Run the test in a subshell to isolate environment
  if [[ $summary_only -eq 0 ]]; then
    logit -i --icon="▶" "Running test: $(ansi "1;97" "$test_name")"
    [[ -n "$test_description" ]] && logit -l "$(ansi "2;90" "$test_description")"
  fi
  
  # Increment total test count
  ((SDK_TESTER_TOTAL_TESTS++))
  
  # Run the test and capture output and exit code
  (
    source "$test_file" > "$test_output_file" 2>&1
    echo $? > "$test_tmp_dir/exit_code"
  )
  
  local exit_code=$(cat "$test_tmp_dir/exit_code")
  local test_end_time=$(date +%s)
  local test_duration=$((test_end_time - test_start_time))
  
  # Record test result
  if [[ $exit_code -eq 0 ]]; then
    ((SDK_TESTER_PASSED_TESTS++))
    if [[ $summary_only -eq 0 ]]; then
      logit -o "Test passed in ${test_duration}s: $(ansi "1;97" "$test_name")"
    fi
  elif [[ $exit_code -eq 77 ]]; then
    ((SDK_TESTER_SKIPPED_TESTS++))
    if [[ $summary_only -eq 0 ]]; then
      logit -w --icon="⏭" "Test skipped: $(ansi "1;97" "$test_name")"
    fi
  else
    ((SDK_TESTER_FAILED_TESTS++))
    if [[ $summary_only -eq 0 ]]; then
      logit -f "Test failed in ${test_duration}s: $(ansi "1;97" "$test_name")"
      logit -e "Test output:"
      cat "$test_output_file" | sed 's/^/    /'
    else
      logit -f "Test failed: $(ansi "1;97" "$test_name") in $(ansi "2;90" "$relative_path")"
    fi
  fi
  
  # Save test results
  mkdir -p "$SDK_TESTER_RESULTS_DIR"
  local results_file="$SDK_TESTER_RESULTS_DIR/$(basename "$test_file" .test.sh).json"
  
  cat > "$results_file" << EOF
{
  "name": "$test_name",
  "file": "$test_file",
  "duration": $test_duration,
  "exitCode": $exit_code,
  "status": "$(if [[ $exit_code -eq 0 ]]; then echo "passed"; elif [[ $exit_code -eq 77 ]]; then echo "skipped"; else echo "failed"; fi)",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  
  # Clean up
  if [[ $exit_code -eq 0 || $summary_only -eq 1 ]]; then
    rm -rf "$test_tmp_dir"
  else
    # Keep the output for failed tests
    cp "$test_output_file" "$SDK_TESTER_RESULTS_DIR/$(basename "$test_file" .test.sh).log"
    rm -rf "$test_tmp_dir"
  fi
  
  # Unset test environment variables
  unset SDK_TEST_FILE SDK_TEST_NAME SDK_TEST_TMP_DIR
  
  return $exit_code
}

# Print a summary of test results
sdk_lib_tester_utils_print_summary() {
  local duration="$1"
  
  echo
  logit -s "$(ansi "1;90" "TEST SUMMARY")"
  echo "$(ansi "90" "───────────────────────────────────────────────────")"
  
  # Print summary statistics
  logit -s "Total tests:   $(ansi "1;97" "$SDK_TESTER_TOTAL_TESTS")"
  logit -s "Passed:        $(ansi "1;32" "$SDK_TESTER_PASSED_TESTS")"
  
  if [[ $SDK_TESTER_FAILED_TESTS -gt 0 ]]; then
    logit -s "Failed:        $(ansi "1;31" "$SDK_TESTER_FAILED_TESTS")"
  else
    logit -s "Failed:        $(ansi "32" "0")"
  fi
  
  if [[ $SDK_TESTER_SKIPPED_TESTS -gt 0 ]]; then
    logit -s "Skipped:       $(ansi "1;33" "$SDK_TESTER_SKIPPED_TESTS")"
  else
    logit -s "Skipped:       $(ansi "32" "0")"
  fi
  
  logit -s "Duration:      $(ansi "97" "${duration}s")"
  
  echo "$(ansi "90" "───────────────────────────────────────────────────")"
  
  # Print final status
  if [[ $SDK_TESTER_FAILED_TESTS -gt 0 ]]; then
    logit -f "$(ansi "1;97" "$SDK_TESTER_FAILED_TESTS") test(s) failed"
  else
    logit -o "All tests passed successfully"
  fi
}

# Skip a test with a reason
sdk_lib_tester_utils_skip() {
  local reason="$1"
  
  logit -w --icon="⏭" "Skipping test: $reason"
  exit 77  # Special exit code for skipped tests
}

# Mark a section in the test
sdk_lib_tester_utils_section() {
  local title="$1"
  
  echo
  logit -s "$(ansi "1;36" "▶") $(ansi "1;97" "$title")"
  echo "$(ansi "90" "───────────────────────────────────────────────────")"
}

# Mark a test as requiring a container
sdk_lib_tester_utils_require_container() {
  if [[ "${SDK_TESTER_IN_CONTAINER:-0}" != "1" ]]; then
    logit -w "This test requires running in a container"
    exit 77  # Skip test
  fi
}

# Execute a command and log the output
sdk_lib_tester_utils_exec() {
  local cmd="$@"
  
  logit -l "$(ansi "90" "$ $cmd")"
  
  # Execute the command and capture output
  local output
  if ! output=$(eval "$cmd" 2>&1); then
    logit -f "Command failed: $cmd"
    logit -e "Output: $output"
    return 1
  fi
  
  # Print output if it's not empty
  if [[ -n "$output" ]]; then
    echo "$output" | sed 's/^/    /'
  fi
  
  return 0
}
