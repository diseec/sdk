# E2E Testing Framework for SDK

This document outlines how to use the end-to-end (E2E) testing framework for the SDK. The framework provides a modular, well-structured approach to testing the SDK's functionality in various environments.

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Writing Tests](#writing-tests)
- [Running Tests](#running-tests)
- [Assertions](#assertions)
- [Project Setup](#project-setup)
- [Container Support](#container-support)
- [Test Discovery](#test-discovery)
- [Examples](#examples)

## Overview

The E2E testing framework is designed to:

- Quickly set up test projects for creating test scenarios
- Support testing in container environments
- Provide elegant, easy-to-use assertions
- Offer a user-friendly API
- Auto-discover tests across the project
- Filter and run specific tests

The framework is implemented as a library within the SDK at `packages/sdk/lib/tester/`.

## Getting Started

### Installation

The testing framework is included in the SDK, so no separate installation is needed. To use it, you need to have the SDK installed in your project.

### Basic Usage

To run all tests:

```bash
d test run
```

To list all available tests:

```bash
d test list
```

To run specific tests:

```bash
d test run --filter=git
```

## Writing Tests

Tests are written as shell scripts that end with `.test.sh`. Each test file should:

1. Include a test name and description as comments
2. Use the assertion functions provided by the framework
3. Return an appropriate exit code

### Test File Structure

```bash
#!/bin/bash

# TEST: My Test Name
# DESCRIPTION: What this test does

# Source testing framework
source_once "$D_SDK_DIR/lib/tester/index.sh"

# Test sections
sdk_lib_tester_utils_section "Section 1"

# Your test assertions
assert_equal "expected" "actual" "Values should be equal"
assert_success "command" "Command should succeed"

# More test sections as needed
sdk_lib_tester_utils_section "Section 2"

# More assertions...

# Return result
exit $(( SDK_TESTER_ASSERT_FAILED > 0 ? 1 : 0 ))
```

### Test Metadata

Each test file should include metadata as comments:

- `# TEST: Test Name` - The name of the test (required)
- `# DESCRIPTION: Test Description` - A brief description of what the test does (optional)

## Running Tests

### Running All Tests

To run all tests in the project:

```bash
d test run
```

### Filtering Tests

To run tests matching a specific pattern:

```bash
d test run --filter=git
```

The filter matches any part of the test file path, making it easy to run related tests.

### Running Specific Tests

To run specific test files:

```bash
d test run path/to/specific.test.sh
```

### Running Tests in a Container

To run tests in the SDK container for a consistent environment:

```bash
d test run --safely
```

### Summary Mode

To only show a summary of test results:

```bash
d test run --summary-only
```

## Assertions

The framework provides a rich set of assertion functions to make testing easier:

### Basic Assertions

```bash
assert_equal "expected" "actual" "Optional message"
assert_not_equal "expected" "actual" "Optional message"
assert_true "condition" "Optional message"
assert_false "condition" "Optional message"
```

### String Assertions

```bash
assert_contains "haystack" "needle" "Optional message"
assert_not_contains "haystack" "needle" "Optional message"
```

### Command Assertions

```bash
assert_success "command" "Optional message"
assert_failure "command" [expected_exit_code] "Optional message"
```

### File Assertions

```bash
assert_file_exists "path/to/file" "Optional message"
assert_dir_exists "path/to/dir" "Optional message"
assert_file_contains "path/to/file" "pattern" "Optional message"
```

## Project Setup

The framework provides utilities to set up test projects:

### Creating a Test Project

```bash
d test setup --name=my-test-project
```

### Using a Template

```bash
d test setup --name=my-test-project --template=custom-template
```

### In Test Scripts

You can also create and manage test projects programmatically in your tests:

```bash
# Create a temporary project
temp_project=$(sdk_lib_tester_create_temp_project)

# Run commands in the project
sdk_lib_tester_run_in_project "$temp_project" "./cli command"

# Clean up when done
sdk_lib_tester_cleanup_temp_project "$temp_project"
```

## Container Support

The framework is designed to work seamlessly with the SDK's container support:

### Testing if Running in Container

```bash
if [[ "${SDK_TESTER_IN_CONTAINER:-0}" == "1" ]]; then
  # Container-specific tests
else
  # Non-container tests
fi
```

### Requiring Container Environment

```bash
# Skip test if not in container
sdk_lib_tester_utils_require_container
```

### Running Tests in Container

```bash
d test run --safely
```

## Test Discovery

The framework automatically discovers tests across the project:

### Test Pattern

Tests are identified by the file extension `.test.sh`.

### Listing Tests

```bash
d test list
```

### Filtering Tests

```bash
d test list --filter=pattern
```

## Examples

Example tests are provided in the `packages/sdk/lib/tester/examples/tests/` directory:

- `basic.test.sh`: Demonstrates basic assertions
- `container.test.sh`: Shows container-aware testing
- `project-setup.test.sh`: Illustrates project setup and testing

Review these examples to get started with your own tests.
