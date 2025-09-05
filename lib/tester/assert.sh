#!/bin/bash

# Assertion utilities for testing framework
# This script provides assertion functions for testing

# Prevent multiple sourcing
if [[ "${SDK_LIB_TESTER_ASSERT_SOURCED:-}" == "1" ]]; then
  return 0
fi
SDK_LIB_TESTER_ASSERT_SOURCED=1

# Track assertion counts
SDK_TESTER_ASSERT_COUNT=0
SDK_TESTER_ASSERT_PASSED=0
SDK_TESTER_ASSERT_FAILED=0

# General-purpose assertion function
sdk_lib_tester_assert() {
  local condition="$1"
  local message="${2:-Assertion failed}"
  local details="${3:-}"
  
  ((SDK_TESTER_ASSERT_COUNT++))
  
  if eval "$condition"; then
    ((SDK_TESTER_ASSERT_PASSED++))
    logit -o --icon="✓" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    return 0
  else
    ((SDK_TESTER_ASSERT_FAILED++))
    logit -f --icon="✖" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    
    if [[ -n "$details" ]]; then
      logit -e "Details: $details"
    fi
    
    # Get caller information
    local caller_info=$(caller 0)
    local line_number=$(echo "$caller_info" | awk '{print $1}')
    local function_name=$(echo "$caller_info" | awk '{print $2}')
    local file_name=$(echo "$caller_info" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}')
    
    logit -e "at $function_name ($file_name:$line_number)"
    
    return 1
  fi
}

# Assert two values are equal
assert_equal() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Expected values to be equal}"
  
  local condition="[[ \"$actual\" == \"$expected\" ]]"
  local details="Expected: '$expected', Actual: '$actual'"
  
  sdk_lib_tester_assert "$condition" "$message" "$details"
}

# Assert two values are not equal
assert_not_equal() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Expected values to be different}"
  
  local condition="[[ \"$actual\" != \"$expected\" ]]"
  local details="Expected not: '$expected', Actual: '$actual'"
  
  sdk_lib_tester_assert "$condition" "$message" "$details"
}

# Assert a value is true
assert_true() {
  local condition="$1"
  local message="${2:-Expected condition to be true}"
  
  sdk_lib_tester_assert "$condition" "$message"
}

# Assert a value is false
assert_false() {
  local condition="$1"
  local message="${2:-Expected condition to be false}"
  
  local negated_condition="! ( $condition )"
  
  sdk_lib_tester_assert "$negated_condition" "$message"
}

# Assert a command succeeds (exit code 0)
assert_success() {
  local cmd="$1"
  local message="${2:-Expected command to succeed}"
  
  local output
  if output=$(eval "$cmd" 2>&1); then
    ((SDK_TESTER_ASSERT_PASSED++))
    logit -o --icon="✓" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    echo "$output"
    return 0
  else
    local exit_code=$?
    ((SDK_TESTER_ASSERT_FAILED++))
    logit -f --icon="✖" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    logit -e "Command: $cmd"
    logit -e "Exit code: $exit_code"
    logit -e "Output: $output"
    
    # Get caller information
    local caller_info=$(caller 0)
    local line_number=$(echo "$caller_info" | awk '{print $1}')
    local function_name=$(echo "$caller_info" | awk '{print $2}')
    local file_name=$(echo "$caller_info" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}')
    
    logit -e "at $function_name ($file_name:$line_number)"
    
    return 1
  fi
}

# Assert a command fails (non-zero exit code)
assert_failure() {
  local cmd="$1"
  local expected_code="${2:-}"  # Optional expected exit code
  local message="${3:-Expected command to fail}"
  
  local output
  if ! output=$(eval "$cmd" 2>&1); then
    local exit_code=$?
    
    # If an expected exit code was provided, check it matches
    if [[ -n "$expected_code" && $exit_code -ne $expected_code ]]; then
      ((SDK_TESTER_ASSERT_FAILED++))
      logit -f --icon="✖" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
      logit -e "Command: $cmd"
      logit -e "Expected exit code: $expected_code, Actual: $exit_code"
      logit -e "Output: $output"
      return 1
    fi
    
    ((SDK_TESTER_ASSERT_PASSED++))
    logit -o --icon="✓" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    echo "$output"
    return 0
  else
    ((SDK_TESTER_ASSERT_FAILED++))
    logit -f --icon="✖" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    logit -e "Command: $cmd"
    logit -e "Expected failure but command succeeded"
    logit -e "Output: $output"
    
    # Get caller information
    local caller_info=$(caller 0)
    local line_number=$(echo "$caller_info" | awk '{print $1}')
    local function_name=$(echo "$caller_info" | awk '{print $2}')
    local file_name=$(echo "$caller_info" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}')
    
    logit -e "at $function_name ($file_name:$line_number)"
    
    return 1
  fi
}

# Assert a string contains a substring
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Expected string to contain substring}"
  
  local condition="[[ \"$haystack\" == *\"$needle\"* ]]"
  local details="Expected to find: '$needle' in: '$haystack'"
  
  sdk_lib_tester_assert "$condition" "$message" "$details"
}

# Assert a string does not contain a substring
assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Expected string not to contain substring}"
  
  local condition="[[ \"$haystack\" != *\"$needle\"* ]]"
  local details="Expected not to find: '$needle' in: '$haystack'"
  
  sdk_lib_tester_assert "$condition" "$message" "$details"
}

# Assert a file exists
assert_file_exists() {
  local file="$1"
  local message="${2:-Expected file to exist}"
  
  local condition="[[ -f \"$file\" ]]"
  local details="File: '$file'"
  
  sdk_lib_tester_assert "$condition" "$message" "$details"
}

# Assert a directory exists
assert_dir_exists() {
  local dir="$1"
  local message="${2:-Expected directory to exist}"
  
  local condition="[[ -d \"$dir\" ]]"
  local details="Directory: '$dir'"
  
  sdk_lib_tester_assert "$condition" "$message" "$details"
}

# Assert a file contains a pattern
assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-Expected file to contain pattern}"
  
  # First check if the file exists
  if [[ ! -f "$file" ]]; then
    ((SDK_TESTER_ASSERT_FAILED++))
    logit -f --icon="✖" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    logit -e "File does not exist: $file"
    return 1
  fi
  
  # Check if the file contains the pattern
  if grep -q "$pattern" "$file"; then
    ((SDK_TESTER_ASSERT_PASSED++))
    logit -o --icon="✓" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    return 0
  else
    ((SDK_TESTER_ASSERT_FAILED++))
    logit -f --icon="✖" "$(ansi "90" "ASSERT") $(ansi "97" "$message")"
    logit -e "Pattern not found in file: '$pattern'"
    logit -e "File: $file"
    
    # Get caller information
    local caller_info=$(caller 0)
    local line_number=$(echo "$caller_info" | awk '{print $1}')
    local function_name=$(echo "$caller_info" | awk '{print $2}')
    local file_name=$(echo "$caller_info" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}')
    
    logit -e "at $function_name ($file_name:$line_number)"
    
    return 1
  fi
}

# Print assertion stats
sdk_lib_tester_assert_stats() {
  logit -s "Assertions: $SDK_TESTER_ASSERT_COUNT, Passed: $SDK_TESTER_ASSERT_PASSED, Failed: $SDK_TESTER_ASSERT_FAILED"
  
  if [[ $SDK_TESTER_ASSERT_FAILED -gt 0 ]]; then
    return 1
  fi
  
  return 0
}
