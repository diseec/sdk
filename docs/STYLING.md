# SDK Styling Guide

This document outlines the styling conventions, color schemes, and design aesthetics used in the SDK. It serves as a reference for developers who want to maintain visual consistency across the codebase or build their own tools that align with the SDK's design language.

## Table of Contents

- [Design Philosophy](#design-philosophy)
- [Color Palette](#color-palette)
- [Text Styles](#text-styles)
- [Message Types](#message-types)
- [Interactive Components](#interactive-components)
- [Examples](#examples)
- [Best Practices](#best-practices)

## Design Philosophy

The SDK's visual design is built around a few core principles:

1. **Clarity**: Visual hierarchy guides the eye to important information
2. **Consistency**: Uniform styling across all components for a cohesive experience
3. **Contextual Meaning**: Colors and icons convey meaning beyond just aesthetic appeal
4. **Terminal Friendliness**: All styling respects terminal limitations and capabilities

The overall aesthetic employs a dark, minimalist style with carefully selected accent colors to indicate importance, status, or interaction type. The styling uses ANSI escape codes for maximum compatibility across terminal environments.

## Color Palette

The SDK uses a specific color palette with each color carrying semantic meaning:

| Color   | ANSI Code | Usage                                     | Example                       |
| ------- | --------- | ----------------------------------------- | ----------------------------- |
| Gray    | `90`      | Default text, timestamps, contextual info | `[12:34:56][SDK]`             |
| White   | `97`      | Emphasis, important labels, commands      | `Usage`                       |
| Red     | `31`      | Errors, failures, critical issues         | `[✖] Failed to connect`      |
| Green   | `32`      | Success, completion, positive outcomes    | `[✓] Installation complete`   |
| Yellow  | `33`      | Warnings, cautions, attention required    | `[!] Deprecation warning`     |
| Blue    | `34`      | Information, prompts, general messages    | `[i] System information`      |
| Magenta | `35`      | Questions, user interactions              | `[?] Do you want to proceed?` |
| Cyan    | `96`      | AI-related features, special actions      | `[✦] Generating insights`     |

### Background Colors

Background colors are used sparingly, mainly for high-emphasis elements:

- Red background (`41`) with white text (`97`): Critical errors
- Yellow background (`43`) with black text (`30`): Important warnings
- Blue background (`44`) with white text (`97`): Key information

## Text Styles

Beyond colors, the SDK uses several text styles to convey meaning:

| Style     | ANSI Code | Usage                           | Example                                |
| --------- | --------- | ------------------------------- | -------------------------------------- |
| Bold      | `1`       | Section headers, command names  | **Usage**                              |
| Dim       | `2`       | Secondary information, examples | _Examples_                             |
| Italic    | `3`       | Emphasis, notes                 | _Note: this requires special handling_ |
| Underline | `4`       | Links, highlights               | <u>https://github.com/</u>             |

Combinations of styles are used for specific purposes:

- Bold + Color: Section headers (`1;90`)
- Dim + Color: Additional information (`2;90`)
- Underline + Color: Interactive links (`4;90`)

## Message Types

The SDK uses a consistent format for different types of messages. Each message type has:

- A timestamp prefix: `[HH:MM:SS]`
- An optional repository name: `[REPO_NAME]`
- A type indicator with an icon: `[i]`, `[✓]`, `[✖]`, etc.
- The message content

### Standard Message Types

```
[12:34:56][SDK][i] This is an information message
[12:34:56][SDK][✓] This is a success message
[12:34:56][SDK][✖] This is an error message
[12:34:56][SDK][!] This is a warning message
[12:34:56][SDK][?] This is a question prompt
[12:34:56][SDK][✦] This is an AI-related message
```

### Tracing and Debugging

The trace output follows a distinct format:

```
[12:34:56][E] in function_name() at file.sh:123 | Exit 1
-------------------------------------------------------------------------------
failed_command_that_caused_error

STACK TRACE ------------------------------------------------------------
  function_name()             file.sh:123
    → failed_command_that_caused_error
  parent_function()           parent.sh:45
  main()                      main.sh:10
  ... and 3 more frames

ENV VARIABLES --------------------------------------------------------
PWD             /path/to/current/directory
D_INI_PWD       /initial/path
...

SYSTEM INFO -----------------------------------------------------------
OS             macOS 12.3
SDK Version    1.0.0
Bash Version   5.1.8
...
```

This format provides comprehensive debugging information while maintaining visual clarity through indentation, section divisions, and color coding.

## Interactive Components

### User Prompts

Questions and confirmations follow this pattern:

```
[12:34:56][SDK][?] Do you want to proceed? [Y/N]
```

### Input Fields

Input fields are displayed as:

```
[12:34:56][SDK][>] Enter your name: [default_value]
```

Where:

- `[>]` is a purple prompt indicator
- The label is shown in normal text
- Optional default values appear in gray brackets

### Help Displays

Help text uses a multi-column layout with careful alignment:

```
USAGE                         d/bash cli [command] [subcommand] [options] [arguments]
                              Documentation at https://github.com/org/repo

GLOBAL MANAGER THE 'D'
    d [option] [arguments]    Locate project root and invoke the project's ./cli
        about                 About SDK, authors, organization, policies and licensing
    Options:
        --patch               Force pull and reinstall sdk into project
                              Ensures a fresh sdk binary is used,
                              when the local sdk is missing, corrupted,
                              or unable to bootstrap the CLI itself.
```

Notice the hierarchical structure with:

- Section headers in bold gray uppercase
- Commands in normal white text
- Descriptions in normal gray text
- Additional details in dim gray text
- Special commands (like AI) with cyan icons

## Examples

### Simple Status Messages

```bash
# Success message
logit -o "Dependencies installed successfully"
# Output: [12:34:56][SDK][✓] Dependencies installed successfully

# Error message
logit -e "Failed to connect to server"
# Output: [12:34:56][SDK][E] Failed to connect to server

# Warning with custom icon
logit -w --icon="⚠" "Disk space running low"
# Output: [12:34:56][SDK][⚠] Disk space running low
```

### Styled Text Output

```bash
# Bold green text
ansi "1;32" "Operation completed successfully"

# Dim gray for additional context
ansi "2;90" "This might take a few minutes"

# Combining styles for header
echo "$(ansi "1;90" "CONFIGURATION")"
```

### Interactive Prompts

```bash
# Confirmation with default action
if confirm "Delete all temporary files?"; then
    # Delete files if user confirms
    rm -rf /tmp/cache/*
fi

# Input with validation
email=$(input "Enter email address:" --validate="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" --error="Please enter a valid email address")

# Password input with hidden characters
password=$(input "Enter password:" --hidden --validate=".{8,}" --error="Password must be at least 8 characters")
```

## Best Practices

When implementing styled output in your own tools:

1. **Be Consistent with Message Types**
   - Use `-i` (info) for general information
   - Use `-o` (okay) for successful operations
   - Use `-e` (error) for errors
   - Use `-w` (warning) for warnings
   - Use `-q` (question) for prompts
   - Use `-a` (ai) for AI-related features

2. **Respect Visual Hierarchy**
   - Use bold text (`1;XX`) for headers and important information
   - Use dim text (`2;XX`) for supplementary information
   - Reserve bright colors for important messages

3. **Follow Timestamp and Context Pattern**
   - Include timestamp and context for all logs
   - Maintain the `[timestamp][context][type] message` format

4. **Use Icons Meaningfully**
   - `✓` for success
   - `✖` for errors/failures
   - `!` for warnings
   - `i` for information
   - `?` for questions
   - `✦` for AI features
   - Custom icons can be used with `--icon="X"`

5. **Handle Input Consistently**
   - Always validate user input
   - Provide clear error messages
   - Show default values in gray brackets
   - Use `--hidden` for sensitive information

6. **Structure Help Text Properly**
   - Use uppercase section headers
   - Align commands and descriptions in columns
   - Group related commands together
   - Include examples for complex commands

7. **Maintain Compatibility**
   - Test styling in different terminal environments
   - Avoid terminal-specific features
   - Reset styles after use with `\033[0m`

By following these guidelines, you'll maintain visual consistency across the SDK and create a polished, professional user experience for all command-line interactions.

## Implementation Reference

All styling functions are defined in `packages/sdk/shared/outputs.sh`:

- `ansi`: Apply ANSI color and style codes to text
- `logit`: Log a message with timestamp, context, and type
- `confirm`: Ask a yes/no question
- `input`: Get user input with validation
- `display_help`: Display formatted help text

Refer to these files for implementation details and examples.
