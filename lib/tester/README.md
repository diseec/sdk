# DISEEC SDK Testing Framework

A simple, elegant, and modular testing framework for shell scripts that follows the DISEEC SDK design principles.

## Features

- ✨ **Beautiful and easy assertions** - Simple, readable assertion functions
- 🔍 **Auto-discovery** - Automatically finds `*.test.sh` files across your project
- 🎯 **Easy filtering** - Filter tests by name or path with simple patterns
- 🎨 **Consistent styling** - Follows SDK styling guidelines with colored output
- 🔧 **Modular architecture** - Clean, extensible API design
- 📊 **Rich reporting** - Detailed test results and statistics

## Quick Start

### 1. Create a test file

Create any file ending with `.test.sh`:

```bash
# auth.test.sh
#!/bin/bash

test_user_authentication() {
    local result=$(authenticate_user "testuser" "password123")
    assert_equals "success" "$result" "User should authenticate successfully"
}

test_invalid_credentials() {
    local result=$(authenticate_user "baduser" "wrongpass")
    assert_equals "failure" "$result" "Invalid credentials should fail"
}
```

### 2. Run your tests

```bash
# Run all tests
d tester run

# Run tests matching a pattern
d tester run auth

# Run with detailed output
d tester run --verbose
```

## Available Commands

| Command            | Description                         | Example                      |
| ------------------ | ----------------------------------- | ---------------------------- |
| `run [pattern]`    | Run all tests or filter by pattern  | `d tester run auth`          |
| `list [pattern]`   | List all discoverable test files    | `d tester list`              |
| `discover`         | Show test discovery paths and stats | `d tester discover`          |
| `filter <pattern>` | Filter and run tests by pattern     | `d tester filter validation` |
| `clean`            | Clean test artifacts and temp files | `d tester clean`             |

## Available Assertions

### Equality Assertions

- `assert_equals <expected> <actual> [message]`
- `assert_not_equals <expected> <actual> [message]`

### String Assertions

- `assert_contains <haystack> <needle> [message]`
- `assert_not_contains <haystack> <needle> [message]`
- `assert_matches <value> <regex_pattern> [message]`
- `assert_empty <value> [message]`
- `assert_not_empty <value> [message]`

### File System Assertions

- `assert_file_exists <path> [message]`
- `assert_file_not_exists <path> [message]`
- `assert_dir_exists <path> [message]`

### Command Assertions

- `assert_command_success <command> [message]`
- `assert_command_fails <command> [message]`

### Numeric Assertions

- `assert_greater_than <value> <threshold> [message]`
- `assert_less_than <value> <threshold> [message]`

### Test Control

- `skip_test [reason]` - Skip current test
- `fail_test [message]` - Fail current test immediately

## Test File Structure

Test files must:

- End with `.test.sh`
- Define functions starting with `test_`
- Use assertion functions for validations

### Optional Lifecycle Hooks

```bash
#!/bin/bash

# Runs once before all tests in this file
suite_setup() {
    export TEST_WORKSPACE=$(create_test_workspace)
}

# Runs once after all tests in this file
suite_teardown() {
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Runs before each individual test
test_setup() {
    export TEST_VAR="initialized"
}

# Runs after each individual test
test_teardown() {
    unset TEST_VAR
}

test_my_feature() {
    assert_equals "expected" "actual" "Feature should work"
}
```

## Command Line Options

| Option          | Description                               |
| --------------- | ----------------------------------------- |
| `--verbose, -v` | Show detailed test output and timing      |
| `--fail-fast`   | Stop on first test failure                |
| `--quiet, -q`   | Minimal output, show only results summary |
| `--dry-run`     | Show what would be tested without running |

## Examples

```bash
# Run all tests
d tester run

# Run tests with "auth" in the name or path
d tester run auth

# Run tests verbosely and stop on first failure
d tester run --verbose --fail-fast

# List all test files
d tester list

# Filter and run specific tests
d tester filter database

# Clean up test artifacts
d tester clean
```

## Helper Functions

### Test Workspace Management

- `create_test_workspace [name]` - Create temporary test directory
- `cleanup_test_workspace <dir>` - Clean up test directory
- `create_test_file <path> [content]` - Create test file
- `create_test_dir <path>` - Create test directory

### Command Mocking

- `mock_command <name> [behavior] [exit_code]` - Mock a command
- `unmock_command <name>` - Remove command mock

## Integration with SDK

The tester is fully integrated with the SDK:

- Follows SDK styling guidelines
- Uses SDK logging and output functions
- Respects SDK context and directory structure
- Available through the main `d` command

## Best Practices

1. **Descriptive test names**: Use clear, descriptive function names

   ```bash
   test_user_can_login_with_valid_credentials()
   ```

2. **One assertion per concept**: Keep tests focused

   ```bash
   test_password_validation() {
       assert_command_fails "validate_password '123'" "Short password should fail"
       assert_command_success "validate_password 'SecurePass123!'" "Strong password should succeed"
   }
   ```

3. **Use meaningful assertion messages**: Help with debugging

   ```bash
   assert_equals "active" "$user_status" "User should be active after registration"
   ```

4. **Clean up after tests**: Use teardown functions for cleanup

   ```bash
   test_teardown() {
       rm -f /tmp/test_file_*
   }
   ```

5. **Group related tests**: Use descriptive file names

   ```bash
   auth.test.sh          # Authentication tests
   database.test.sh      # Database tests
   validation.test.sh    # Input validation tests
   ```

6. **Try to keep it e2e**: Use 'D' command

   ```bash
    version_output=$(D --version)

    # Test that output contains expected elements
    assert_not_empty "$version_output" "Version output should not be empty"
   ```

## Output Examples

### Successful test run:

```
[12:34:56][SDK][i] DISEEC SDK TESTING FRAMEWORK

[12:34:56][SDK][i] Discovered 3 test file(s)

▶ Running examples/basic.test.sh
  ✓ 8 passed, 0 failed, 0 skipped

▶ Running examples/utilities.test.sh
  ✓ 6 passed, 0 failed, 1 skipped

[12:34:56][SDK][i] TEST RESULTS SUMMARY

✓ Passed:   14
✖ Failed:   0
⊘ Skipped:  1
• Total:    15

✓ Success Rate: 100%
• Duration:   2s

[12:34:56][SDK][✓] All tests passed! 🎉
```

### Test with failures:

```
[12:34:56][SDK][✖] Values should be equal
Expected: hello
Actual:   world

[12:34:56][SDK][i] TEST RESULTS SUMMARY

✓ Passed:   12
✖ Failed:   3
⊘ Skipped:  1
• Total:    16

✖ Success Rate: 75%
• Duration:   2s

[12:34:56][SDK][✖] Some tests failed. Fix them and try again.
```

---

The DISEEC SDK Testing Framework provides everything you need to write reliable, maintainable tests for your shell scripts while maintaining the beautiful, consistent experience you expect from the SDK.
