# Testing Guidelines for tester Framework

## Introduction

This document provides comprehensive guidelines, best practices, and lessons learned for writing effective tests in the tester framework. It aims to help developers quickly understand the testing approach, common pitfalls, and techniques that work well in this specific environment.

## Core Principles

1. **End-to-End Testing**: Tests should emulate real user behavior. Always prefer end-to-end tests that exercise commands exactly as a user would.

2. **Don't Mask Command Responsibilities**: Tests must challenge commands properly and should not "prepare" things that are the command's responsibility. Let the command handle its own prerequisites.

3. **Report Framework Issues**: If you encounter limitations in the testing framework itself, don't work around them in your tests. Report the issue so we can improve the framework. Tests should not contain workarounds for framework limitations.

4. **Separation of Concerns**: Never use internal variables or implementation details of the testing framework in your tests. Tests should only interact with the public API of the tool being tested.

5. **No Conditional Assertions**: Conditional assertions (if/then assertions) are strongly forbidden. All scenarios must be clearly prepared and tested individually.

6. **Let Assertions Determine Test Outcome**: Never use `return` or `exit` to control test outcomes. Let assertions determine success or failure. Early returns create false positives.

7. **Avoid False Positives**: Design tests to avoid false positives and unstable behavior. Tests should definitively pass or fail based on actual functionality.

8. **Explicit Verification Beyond Exit Status**: Assertions must verify actual outcomes, not just exit status. Never rely solely on success exit codes - validate that the command's purpose was fully accomplished through observable results.

## Table of Contents

1. [Test Structure](#test-structure)
2. [Assertion Best Practices](#assertion-best-practices)
3. [Working with BusyBox Constraints](#working-with-busybox-constraints)
4. [Capturing and Inspecting Command Output](#capturing-and-inspecting-command-output)
5. [Handling Different Environments](#handling-different-environments)
6. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
7. [Test Design Principles](#test-design-principles)
8. [Testing Interactive Commands](#testing-interactive-commands)
9. [Quick Reference](#quick-reference)

## Test Structure

Tests in the tester framework follow a specific structure:

```bash
#!/bin/bash

# Test for the 'command or feature'

# Suite setup (optional) - runs once before all tests in this file
suite_setup() {
    # Initialize any required state
    D some-command init
    return 0
}

# Suite teardown (optional) - runs once after all tests in this file
suite_teardown() {
    # Clean up any global resources created during testing
    # Note: You don't need to clean up the test workspace
    return 0
}

# Individual test function
test_specific_feature() {
    # Each test function gets a fresh $TEST_CTX automatically
    # and the current directory is already set to it

    # Setup specific to this test (if needed)
    D some-command setup-action

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
3. **Workspaces**: The framework automatically creates a fresh `$TEST_CTX` for each test function. You don't need to create or clean up workspaces manually.

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

## Capturing and Inspecting Command Output

The testing framework automatically captures output for all `D` commands, recording execution details for debugging without any additional effort from the test writer:

### Automatic Command Logging

```bash
# Command output is automatically captured without any special syntax
test_command_with_automatic_logging() {
    # Run command and capture its output directly - no special syntax needed
    local result=$(D some-command --option)

    # Now you can make assertions on the command output
    assert_contains "$result" "expected message" "Command should produce expected output"
}
```

### Benefits of Automatic Logging

1. **Debug Information**: When tests fail, the full command output is displayed automatically.
2. **No Silent Failures**: Avoids hiding useful debug information.
3. **Simplicity**: No need for temporary files or complex redirections.
4. **Complete Logging**: Captures command, output, and exit code for easier debugging.
5. **Zero Effort**: Test writers don't need to remember special syntax or wrappers.

### The `capture_test_log` Function for Non-D Commands

For commands other than `D` (like system commands or complex operations), you can use the `capture_test_log` function:

```bash
# For system commands or complex operations
result=$(capture_test_log ls -la)

# For commands with pipes, redirections, or complex syntax
result=$(capture_test_log "grep 'pattern' file.txt | wc -l")
```

### Best Practices for Command Execution

1. **Use D Commands Directly**: Simply use `D` commands as normal.
2. **Use `capture_test_log` for Non-D Commands**: For system commands or complex operations, use the `capture_test_log` function.
3. **Keep Original Output**: Avoid unnecessary transformations that might hide relevant information.
4. **Selective Assertions**: Don't assert on the entire output; focus on specific parts that matter.

```bash
# Good usage pattern:
test_example_command_execution() {
    # D commands capture output automatically
    local output=$(D complex-command --with-options)

    # Make targeted assertions
    assert_contains "$output" "Operation succeeded" "Success message should be present"
    assert_equals "0" "$?" "Command should exit successfully"

    # For non-D commands, use capture_test_log
    local system_output=$(capture_test_log grep "pattern" /etc/hosts)
    assert_contains "$system_output" "localhost" "Pattern should be found"

    # Run more D commands
    D cleanup-after-test
}
```

## Handling Different Environments

Tests must work in different environments:

1. **Paths**: Always use `$TEST_CTX` rather than hardcoded paths.
2. **Command Output Redirection**: Redirect command output to `/dev/null` when not testing the output directly.
3. **Tool Availability**: Be aware that different environments may have different tools available.

## Test Design Principles

### End-to-End Testing

Tests should mimic real user behavior as closely as possible:

```bash
# GOOD: Testing the command as a user would
test_config_set_command() {
    # Run the command exactly as a user would
    local output=$(D config set my.setting "my value")

    # Verify the result
    local get_result=$(D config get my.setting)
    assert_equals "my value" "$get_result" "Config value should be set correctly"
}

# BAD: Bypassing the command's normal operation
test_config_set_command_bad() {
    # Don't directly manipulate config files - this bypasses the command's logic
    echo "my value" > "$CONFIG_DIR/my.setting"

    # This doesn't test the actual command!
    assert_equals "my value" "$(capture_test_log cat "$CONFIG_DIR/my.setting")" "Config should be set"
}
```

### Command Responsibility

Tests should challenge the command properly and let it handle its own responsibilities:

```bash
# GOOD: Let the command handle its prerequisites
test_secret_add_command() {
    # Run the command directly, let it create its directory structure
    # Use capture_test_log for the echo pipe since it's not a D command
    local output=$(capture_test_log echo -e "SECRET_NAME\nsecret_value" | D secret add)

    # Verify the command succeeded and did its job
    assert_contains "$output" "added successfully" "Should indicate success"

    local secret_value=$(D secret export SECRET_NAME)
    assert_equals "secret_value" "$secret_value" "Secret should be stored correctly"
}

# BAD: Preparing things that are the command's job
test_secret_add_command_bad() {
    # Don't pre-create directories or set up infrastructure for the command
    mkdir -p "/path/to/secrets"
    touch "/path/to/encryption_key"

    # This doesn't test whether the command can set up its prerequisites
    D secret add ...
}
```

### Framework Limitations

When encountering limitations in the testing framework:

```bash
# GOOD: Report framework limitations, don't work around them
# If you find that the framework doesn't support a certain testing scenario,
# open an issue and request enhancement instead of creating brittle workarounds.

# BAD: Creating workarounds for framework limitations
test_with_workaround() {
    # Don't do this - modifying framework internals or creating workarounds
    _INTERNAL_TESTER_VARIABLE="modified"

    # Special handling for framework limitation XYZ...
    # Complex workaround code...
}
```

### No Framework Implementation Details

Tests should not depend on internal variables or implementation details:

```bash
# GOOD: Use only public interfaces
test_command_execution() {
    # Use only the public command interface
    local result=$(D my-command --option)
    assert_equals "expected output" "$result" "Command should produce expected output"
}

# BAD: Using framework implementation details
test_command_with_internals() {
    # Don't use or modify internal variables of the testing framework
    _INTERNAL_TEST_FLAG=true

    # Don't directly invoke internal functions
    _run_test_internal_function
}
```

Remember: If you're writing complex workarounds in your tests, you're likely masking issues that should be fixed in either the command implementation or the testing framework.

### No Conditional Assertions

All test scenarios must be explicitly prepared and tested independently. Conditional assertions create ambiguity and can hide failures:

```bash
# BAD: Conditional assertions make test outcomes unclear
test_conditional_assertions_bad() {
    local result=$(D some-command)

    # DON'T DO THIS: Test logic is obfuscated
    if echo "$result" | grep -q "success"; then
        assert_equals "expected output" "$result" "Success path"
    else
        assert_contains "$result" "error message" "Error path"
    fi

    # This test can "pass" in different ways, making it unclear what was tested
}

# GOOD: Clear, separate tests for each scenario
test_command_success_case() {
    # Set up success scenario
    local result=$(D some-command --success-param)

    # Always assert the expected outcome
    assert_equals "expected output" "$result" "Command should succeed with expected output"
}

test_command_error_case() {
    # Set up error scenario explicitly
    local result=$(D some-command --error-param)

    # Assert the error condition
    assert_contains "$result" "error message" "Command should show appropriate error"
}
```

### Let Assertions Control Test Outcomes

Tests should never manually control their pass/fail status. Let assertions determine the test outcome:

```bash
# BAD: Manual returns create false positives
test_with_early_returns_bad() {
    # DON'T DO THIS: Early returns bypass assertions
    if [ ! -f "$TEST_CTX/some-file" ]; then
        return 0  # DANGEROUS! Test "passes" without asserting anything
    fi

    # This assertion might never run:
    assert_equals "expected" "$(cat "$TEST_CTX/some-file")" "File content check"
}

# GOOD: Assertions control outcome
test_file_content_good() {
    # Create the test file if testing its existence is not the main purpose
    touch "$TEST_CTX/some-file"
    echo "content" > "$TEST_CTX/some-file"

    # Always make assertions - let them determine pass/fail
    assert_file_exists "$TEST_CTX/some-file" "File should exist"
    assert_equals "content" "$(cat "$TEST_CTX/some-file")" "File content check"
}
```

### Avoid False Positives and Unstable Tests

Design tests to be deterministic and definitively validate functionality:

```bash
# BAD: Unstable test that might pass incorrectly
test_unstable_test_bad() {
    # DON'T DO THIS: Race condition with timing
    D start-background-service
    sleep 1  # Arbitrary sleep, might be too short or too long

    # May pass or fail depending on timing
    local result=$(D check-service-status)
    assert_contains "$result" "running" "Service should be running"
}

# GOOD: More deterministic approach
test_service_startup_good() {
    # Start service and poll with timeout for deterministic result
    D start-background-service

    local timeout=10
    local counter=0
    local status=""

    while [ $counter -lt $timeout ]; do
        status=$(D check-service-status)
        if echo "$status" | grep -q "running"; then
            break
        fi
        counter=$((counter + 1))
        sleep 1
    done

    # Clear assertion of the expected state
    assert_contains "$status" "running" "Service should be running within $timeout seconds"
    assert_less_than $counter $timeout "Service should start before timeout"
}
```

### Verify Beyond Exit Status

Tests must validate actual outcomes, not just whether a command exited successfully:

```bash
# BAD: Only checking exit status
test_command_exit_status_only_bad() {
    # DON'T DO THIS: Only checking if command runs without error
    assert_command_success "D create-user john" "User creation should succeed"

    # Missing: Verification that the user was actually created correctly
}

# GOOD: Verifying actual outcomes
test_user_creation_good() {
    # Run the command
    local output=$(D create-user john)

    # Verify exit status
    assert_equals "0" "$?" "User creation should succeed"

    # IMPORTANT: Verify the actual outcome through observable results
    assert_contains "$output" "User created successfully" "Command should report success"

    local list_output=$(D list-users)
    assert_contains "$list_output" "john" "User should appear in user list"

    local username=$(D get-user-property john username)
    assert_equals "john" "$username" "Username should be set correctly"
}
```

Even for commands that don't produce obvious output, find ways to verify their effects:

```bash
# BAD: Only checking if a setup command runs
test_environment_setup_bad() {
    assert_command_success "D setup-environment" "Environment setup should succeed"
    # Missing verification that the setup actually did something
}

# GOOD: Verifying the effects of the command
test_environment_setup_good() {
    # Run the setup command
    local output=$(D setup-environment)

    # Verify exit status
    assert_equals "0" "$?" "Environment setup should succeed"

    # Verify actual effects
    assert_file_exists "/expected/config/path" "Setup should create config file"

    # Use capture_test_log for file reading since it's not a D command
    local config_content=$(capture_test_log cat /expected/config/path)
    assert_contains "$config_content" "expected_setting" "Config should have correct content"

    local check_result=$(D environment-check)
    assert_equals "0" "$?" "Environment validation should pass"

    # For cleanup commands, verify things were actually cleaned up
    D cleanup-temp-files
    assert_file_not_exists "/tmp/should-be-gone" "Temp files should be removed"
}
```

Remember: A command can exit with status 0 but still fail to accomplish its purpose. Always verify the actual, observable outcomes.

### Testing Interactive Commands

Interactive commands that require user input present special challenges for testing. The framework provides several ways to handle these scenarios while maintaining the end-to-end testing approach:

#### Using Here Strings and Here Documents

The most reliable way to test interactive commands is using Bash's here strings (`<<<`) and here documents (`<<EOF ... EOF`):

```bash
# Using here string for a single input
local output=$(D interactive-command <<< "y")

# Using here string for multiple inputs (for simple cases require less than 2 simple inputs)
local output=$(D submodule select <<< $'y\n1,2')

# Using here document for multiple lines of input
local output=$(D interactive-sequence << EOF
username
password
y
option1
EOF
)
```

#### Best Practices for Interactive Command Testing

1. **Use Clear Inputs**: Make inputs clear and explicit in the test. Prefer `<<` syntax for inputs that require newlines.

2. **Test All Input Paths**: Create separate test functions for different input scenarios (valid, invalid, empty, etc.).

3. **Avoid External Input Files**: Define input directly in the test using here strings/documents rather than reading from external files.

4. **Verify Complete Processing**: Verify not just that the command accepted the input, but that it fully processed it correctly.

5. **Document Input Format**: Add comments explaining the expected input format, especially for complex interactive sequences.

6. **Test Edge Cases**: Include tests for boundary conditions like empty input, maximum length input, or special characters.

Remember that automated tests for interactive commands should be as reliable and deterministic as any other test, despite the complexity of handling user input. Treat interactive commands just like how a real user would use.

````

## Quick Reference

### Most Reliable Assertion Patterns

```bash
# 1. Exact value comparison (best)
assert_equals "expected value" "$actual_value" "Message"

# 2. Simple string presence check
local output=$(D command_to_check)
echo "$output" | grep -F "$needle" > /dev/null
assert_equals "$?" "0" "String should contain substring"

# 3. Command success check
local result=$(D some-command)
assert_equals "0" "$?" "Command should succeed"
# Or using the dedicated helper with result:
local result=$(D some-command)
assert_command_success "echo $?" "Command should succeed"

# 4. Checking array content and iteration
local count=0
for item in $array_value; do
    count=$((count + 1))
done
assert_equals "3" "$count" "Array should have 3 items"

# 5. Working with files in the test workspace (use capture_test_log for file operations)
$(capture_test_log "echo 'test content' > $TEST_CTX/test-file.txt")
assert_file_exists "$TEST_CTX/test-file.txt" "Test file should exist"

# 6. Capturing and inspecting command output
local result=$(D some-command --option)
assert_contains "$result" "expected output" "Command should output expected text"

# 7. Capturing complex commands that aren't D commands
local result=$(capture_test_log "grep pattern file.txt | wc -l")
assert_equals "0" "$?" "Complex command should succeed"

# 8. Using D commands directly
D setup-environment
# Test continues...
````

### Key Principles Checklist

When writing a test, ensure it follows these principles:

1. **End-to-End Focus**: Does the test use the command exactly as a user would?
2. **Command Responsibility**: Does the test allow the command to handle its own prerequisites?
3. **Framework Independence**: Does the test avoid using internal testing framework details?
4. **Real-world Behavior**: Does the test validate behavior a real user would care about?
5. **Reliability**: Is the test deterministic and not flaky?
6. **No Conditional Assertions**: Does each test have clear, unconditional assertions?
7. **Assertion-Driven**: Does the test let assertions control pass/fail status without manual returns?
8. **Scenario Isolation**: Is each scenario tested in isolation without conditionals?
9. **False-Positive Protection**: Is the test designed to fail if the functionality is broken?
10. **Complete Verification**: Does the test verify actual outcomes beyond just exit status?

Remember that well-written tests serve as documentation and safeguard against regressions. Take the time to write clear, thorough, and reliable tests that properly challenge the functionality being tested.
