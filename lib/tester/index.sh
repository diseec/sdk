#!/bin/bash

# Main entry point for the e2e testing framework
# This script loads all required components of the testing framework

# Prevent multiple sourcing
if [[ "${SDK_LIB_TESTER_SOURCED:-}" == "1" ]]; then
  return 0
fi
SDK_LIB_TESTER_SOURCED=1

# Ensure we have SDK environment
if [[ -z "${D_SDK_DIR:-}" ]]; then
  echo "Error: D_SDK_DIR is not set. Testing framework must be used within the SDK environment."
  return 1
fi

# Source dependencies
source_once "$D_SDK_DIR/index.sh"

# Load core testing utilities
source_once "$D_SDK_DIR/lib/tester/utils.sh"
source_once "$D_SDK_DIR/lib/tester/assert.sh"
source_once "$D_SDK_DIR/lib/tester/setup.sh"

# Set constants
export SDK_TESTER_DIR="$D_SDK_DIR/lib/tester"
export SDK_TESTER_VERSION="1.0.0"

# Initialize testing environment
sdk_lib_tester_init() {
  logit -i --icon="✦" "Initializing E2E Testing Framework v${SDK_TESTER_VERSION}"
  
  # Ensure test results directory exists
  export SDK_TESTER_RESULTS_DIR="${SDK_TESTER_RESULTS_DIR:-$D_CTX_DIR/.test-results}"
  mkdir -p "$SDK_TESTER_RESULTS_DIR"
  
  # Initialize counters
  export SDK_TESTER_TOTAL_TESTS=0
  export SDK_TESTER_PASSED_TESTS=0
  export SDK_TESTER_FAILED_TESTS=0
  export SDK_TESTER_SKIPPED_TESTS=0
  
  # Set flag for container awareness
  if sdk_boo_env_uti_is_in_container; then
    export SDK_TESTER_IN_CONTAINER=1
  else
    export SDK_TESTER_IN_CONTAINER=0
  fi
}

# Main function to run tests
sdk_lib_tester_run() {
  local test_files=()
  local filter=""
  local summary_only=0
  local safely_flag=0
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --filter=*)
        filter="${1#*=}"
        shift
        ;;
      --summary-only)
        summary_only=1
        shift
        ;;
      --safely)
        safely_flag=1
        shift
        ;;
      *)
        test_files+=("$1")
        shift
        ;;
    esac
  done
  
  # If no specific test files are provided, discover all tests
  if [[ ${#test_files[@]} -eq 0 ]]; then
    test_files=($(sdk_lib_tester_utils_discover_tests))
    
    # Filter tests if requested
    if [[ -n "$filter" ]]; then
      local filtered_tests=()
      for test_file in "${test_files[@]}"; do
        if [[ "$test_file" == *"$filter"* ]]; then
          filtered_tests+=("$test_file")
        fi
      done
      test_files=("${filtered_tests[@]}")
    fi
  fi
  
  # Check if we need to run in container
  if [[ $safely_flag -eq 1 && $SDK_TESTER_IN_CONTAINER -eq 0 ]]; then
    logit -i "Running tests in SDK container for consistent environment"
    safely sdk_lib_tester_run "$@"
    return $?
  fi
  
  # Initialize the testing environment
  sdk_lib_tester_init
  
  # Run tests
  local start_time=$(date +%s)
  
  logit -i "Running ${#test_files[@]} test files"
  
  for test_file in "${test_files[@]}"; do
    sdk_lib_tester_utils_run_test_file "$test_file" "$summary_only"
  done
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  # Print summary
  sdk_lib_tester_utils_print_summary "$duration"
  
  # Return non-zero exit code if any tests failed
  if [[ $SDK_TESTER_FAILED_TESTS -gt 0 ]]; then
    return 1
  fi
  
  return 0
}

# Entry point if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  sdk_lib_tester_run "$@"
fi
