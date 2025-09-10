# Testing Guidelines for tester Framework

## Introduction

This document provides comprehensive guidelines, best practices, and lessons learned for writing effective tests in the tester framework. It aims to help developers quickly understand the testing approach, common pitfalls, and techniques that work well in this specific environment.

## Table of Contents

1. [Test Structure](#test-structure)
2. [Assertion Best Practices](#assertion-best-practices)
3. [Working with BusyBox Constraints](#working-with-busybox-constraints)
4. [Testing Configuration Values](#testing-configuration-values)
5. [Handling Different Environments](#handling-different-environments)
6. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
7. [Quick Reference](#quick-reference)

## Test Structure

Tests in the tester framework follow a specific structure:

```bash
#!/bin/bash

# Test for the 'command or feature'

# Suite setup - runs once before all tests in this file
suite_setup() {
    # Initialize any required state
    D some-command init > /dev/null
}

# Suite teardown - runs once after all tests in this file
suite_teardown() {
    # Clean up any global resources created during testing
    # Note: You don't need to clean up the test workspace
    return 0
}

# Individual test function
test_specific_feature() {
    # Each test function gets a fresh $TEST_WORKSPACE automatically
    # and the current directory is already set to it

    # Setup specific to this test (if needed)
    D some-command setup-action > /dev/null

    # Execute the code under test
    local result
    result=$(D some-command action-to-test)

    # Assertions
    assert_equals "expected" "$result" "Message describing the expectation"

    # No need to clean up the workspace - it's handled automatically
}
```

### Key Components:

1. **Suite Setup/Teardown**: These run once for the entire test file.
2. **Test Functions**: Must be prefixed with `test_` to be discovered by the test runner.
3. **Workspaces**: The framework automatically creates a fresh `$TEST_WORKSPACE` for each test function. You don't need to create or clean up workspaces manually.

## Assertion Best Practices

The testing framework provides several assertion functions:

| Function                 | Purpose                              | Example                                           |
| ------------------------ | ------------------------------------ | ------------------------------------------------- |
| `assert_equals`          | Compare exact values                 | `assert_equals "expected" "$actual" "Message"`    |
| `assert_contains`        | Check if string contains a substring | `assert_contains "$haystack" "$needle" "Message"` |
| `assert_command_success` | Verify command exit code is 0        | `assert_command_success "some command" "Message"` |
| `assert_matches`         | Check if string matches a pattern    | `assert_matches "$value" "pattern" "Message"`     |
| `assert_empty`           | Check if string is empty             | `assert_empty "$value" "Message"`                 |

### Important Findings:

1. **Exact Assertions are Better**: Always prefer exact value comparisons with `assert_equals` over pattern matching when possible.

2. **BusyBox Compatibility**: The `assert_contains` and `assert_matches` functions may have issues in BusyBox environments due to limited grep functionality. When in doubt, use:

   ```bash
   echo "$haystack" | grep -F "$needle" > /dev/null
   assert_equals "$?" "0" "Message"
   ```

3. **Multiline Strings**: When comparing multiline outputs, normalize the output first:

   ```bash
   normalized_output=$(echo "$output" | tr -s ' \t\n')
   normalized_expected=$(echo "$expected" | tr -s ' \t\n')
   assert_equals "$normalized_expected" "$normalized_output" "Message"
   ```

4. **For Complex Assertions**: Break down complex assertions into multiple simpler ones.

## Working with BusyBox Constraints

When working in Docker containers or other environments that use BusyBox, you'll encounter limitations with command functionality:

### BusyBox grep Limitations

BusyBox's grep has fewer options than GNU grep. In particular:

1. **Use -F for Fixed Strings**: Always use `grep -F` for literal string searches, not regex patterns.
2. **Avoid Complex Regex**: BusyBox grep has limited regex support.
3. **Explicit Exit Code Checks**: When using grep, check its exit code explicitly:

```bash
echo "$haystack" | grep -F "$needle" > /dev/null
assert_equals "$?" "0" "Message"
```

### Other BusyBox Considerations

1. **Prefer Basic Tools**: Stick to the most basic Unix utilities where possible.
2. **Text Processing**: For text processing, use `tr`, `sed`, and `awk` with basic options only.
3. **Explicit Comparisons**: Be explicit in your comparisons rather than relying on pattern matching.

## Handling Different Environments

Tests must work in different environments:

1. **Paths**: Always use `$TEST_WORKSPACE` rather than hardcoded paths.
2. **Command Output Redirection**: Redirect command output to `/dev/null` when not testing the output directly.
3. **Tool Availability**: Be aware that different environments may have different tools available.

## Quick Reference

### Most Reliable Assertion Patterns

```bash
# 1. Exact value comparison (best)
assert_equals "expected value" "$actual_value" "Message"

# 2. Simple string presence check
echo "$haystack" | grep -F "$needle" > /dev/null
assert_equals "$?" "0" "String should contain substring"

# 3. Command success check
D some-command > /dev/null
assert_equals "$?" "0" "Command should succeed"
# Or using the dedicated helper:
assert_command_success "D some-command" "Command should succeed"

# 4. Checking array content and iteration
local count=0
for item in $array_value; do
    count=$((count + 1))
done
assert_equals "3" "$count" "Array should have 3 items"

# 5. Working with files in the test workspace
echo "test content" > "$TEST_WORKSPACE/test-file.txt"
assert_file_exists "$TEST_WORKSPACE/test-file.txt" "Test file should exist"
```

Remember that well-written tests serve as documentation and safeguard against regressions. Take the time to write clear, thorough, and reliable tests.
