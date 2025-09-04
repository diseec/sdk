# SDK Trace System

This document explains the comprehensive trace system implemented in the SDK for debugging Bash applications.

## Overview

The trace system is designed to provide detailed stack traces and error information when issues occur in your Bash scripts. It automatically captures the error context, including:

- Error code and command that failed
- Function call stack with file names and line numbers
- Environmental variables relevant to debugging
- System information

## Configuration Variables

The trace system can be configured via the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `D_TRACE_ENABLED` | `true` | Enable/disable the trace system |
| `D_TRACE_DEPTH` | `10` | Maximum number of stack frames to show |
| `D_TRACE_FILE` | `/tmp/d_trace_*.log` | File to log traces to |
| `D_LOG_LEVEL` | `INFO` | Log level (DEBUG, INFO, WARNING, ERROR) |
| `DEBUG` | `false` | Enable/disable debug mode |
| `D_EXIT_ON_ERROR` | `true` | Whether to exit on error |

## Basic Usage

The trace system is automatically initialized when the SDK is loaded. When an error occurs, a detailed trace will be displayed and logged to the trace file.

### Example Error Output

```
==== ERROR DETECTED ====
Error code: 1
Location: process_file() in sdk/src/core/utils.sh line 123
Command: cat $nonexistent_file

Stack Trace (most recent call first):
#0 process_file() at sdk/src/core/utils.sh:123
    Command: cat $nonexistent_file
#1 handle_request() at sdk/src/api/requests.sh:45
#2 main() at sdk/src/cli.sh:67
... and 2 more frames

System Information:
- Working directory: /Users/username/project
- Bash version: 5.1.16(1)-release
- SDK directory: /Users/username/project/packages/sdk

Full trace logged to: /tmp/d_trace_20250904_123456.log
```

## Debug Utility Functions

The trace system includes several utility functions for debugging:

### `debug_stack()`

Print the current call stack at any point (not just on error):

```bash
# Inside your function
debug_stack
```

### `debug_vars([prefix])`

Print all variables with a given prefix (default: `D_`):

```bash
# Print all D_* variables
debug_vars

# Print all MY_* variables
debug_vars "MY_"
```

### `debug_args()`

Print a function's arguments for debugging:

```bash
my_function() {
    debug_args "$@"
    # Rest of your function...
}
```

### `debug_separator([title], [char], [width])`

Print a visual separator for log output:

```bash
debug_separator "IMPORTANT SECTION" "=" 80
```

### `debug_time command [args...]`

Benchmark execution time of commands:

```bash
debug_time expensive_operation arg1 arg2
```

## Advanced Usage

### Manually Controlling Tracing

You can manually control the trace system with these functions:

```bash
# Disable tracing
stop_tracing

# Enable tracing
start_tracing
```

### Controlling Error Behavior

You can control how errors are handled:

```bash
# Make errors non-fatal (script continues after errors)
disable_error_exit

# Make errors fatal (script exits on error)
enable_error_exit

# Enable strict variable checking (unset variables are errors)
enable_strict_vars

# Disable strict variable checking
disable_strict_vars
```

### Getting Stack Traces Programmatically

You can get the current stack trace as a string:

```bash
local trace=$(get_stack_trace)
echo "$trace"
```

## Error Logging

All error traces are automatically logged to the file specified in `D_TRACE_FILE`. This provides a persistent record of errors even if the terminal output is lost.

The log includes:
- Timestamp
- Error code
- Working directory
- Environment variables (SDK and D_ prefixed)
- Full stack trace
