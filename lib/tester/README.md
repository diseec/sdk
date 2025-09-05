# SDK Testing Library

A unified testing framework for the SDK, supporting both unit and end-to-end (E2E) testing.

## Features

- Simple, consistent API for writing both unit and E2E tests
- Comprehensive assertion library
- Clean test output with color formatting
- Isolated test environment for each test
- Support for test timeouts
- Test discovery and execution

## Directory Structure

```
testing/
├── bin/                   # Executable test runners
│   ├── run.sh             # Main test runner script
│   ├── run-unit.sh        # Unit test runner
│   └── run-e2e.sh         # E2E test runner
├── core/                  # Core functionality
│   ├── bootstrap.sh       # Environment setup
│   ├── runner.sh          # Test execution engine
│   ├── discovery.sh       # Test discovery
│   └── reporting.sh       # Test result reporting
├── lib/                   # Supporting libraries
│   ├── assertions.sh      # Assertion functions
│   ├── formatting.sh      # Output formatting
│   ├── utils.sh           # General utilities
│   └── mocks.sh           # Test mocking utilities
├── frameworks/            # Test frameworks
│   ├── unit/              # Unit testing framework
│   │   └── framework.sh   # Unit test helpers
│   └── e2e/               # E2E testing framework
│       └── framework.sh   # E2E test helpers
├── examples/              # Example test files
│   ├── unit/              # Unit test examples
│   └── e2e/               # E2E test examples
└── index.sh               # Main entry point
```

## Usage

### Running Tests

```bash
# Run all tests
./lib/testing/bin/run.sh

# Run only unit tests
./lib/testing/bin/run.sh --unit

# Run only E2E tests
./lib/testing/bin/run.sh --e2e

# Run a specific test file
./lib/testing/bin/run.sh path/to/test.sh

# List available tests
./lib/testing/bin/run.sh --list
```

### Writing Unit Tests

Unit tests should be placed in a `tests/unit` directory with the naming pattern `*.test.sh`.

```bash
#!/bin/bash
# Example unit test

# Source the testing framework
source "$D_SDK_DIR/lib/testing/frameworks/unit/framework.sh"

test_section "Example Section"

test_case "Example test case"
assert_equals "1 + 1 should equal 2" 2 $((1 + 1))
```

### Writing E2E Tests

E2E tests should be placed in a `tests/e2e` directory with the naming pattern `*.e2e.test.sh`.

```bash
#!/bin/bash
# Example E2E test

# Source the testing framework
source "$D_SDK_DIR/lib/testing/frameworks/e2e/framework.sh"

test_section "CLI Commands"

test_case "Version command"
e2e_run_command "d --version"
e2e_assert_success "Command should succeed"
e2e_assert_output_contains "Should show version" "v"
```

## Available Assertions

The testing library provides a rich set of assertions for validating test behavior:

- `assert_equals` - Assert that two values are equal
- `assert_not_equals` - Assert that two values are not equal
- `assert_contains` - Assert that a string contains a substring
- `assert_matches` - Assert that a string matches a regex pattern
- `assert_success` - Assert that a command succeeds
- `assert_failure` - Assert that a command fails
- ... and many more

## Environment

Tests run in an isolated environment with the following variables set:

- `D_SDK_DIR` - Path to the SDK root directory
- `TEST_TEMP_DIR` - A temporary directory for test artifacts
- `CURRENT_TEST_FILE` - Path to the current test file

## License

See the SDK license for details.
