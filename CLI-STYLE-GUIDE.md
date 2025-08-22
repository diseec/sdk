# CLI Style Guide

> **Standardized color codes and styling conventions for DISEEC DevOps Kit CLI**

## Overview

This document outlines the standardized color codes and styling conventions used throughout the DISEEC DevOps Kit CLI. Consistent styling ensures a professional user experience and clear communication of different message types.

## Color Code System

The CLI uses ANSI color codes in the `message` and `color` functions to provide visual feedback. Color codes are categorized by purpose and follow a logical system.

### Color Code Ranges

- **30-39**: Text colors (foreground)
- **40-49**: Background colors (filled backgrounds)
- **Special Effects**: Bold, underline, etc.

## Message Type Classifications

### Text Colors (30-39)

| Code | Type      | Color           | Usage                                        | Example                                    |
| ---- | --------- | --------------- | -------------------------------------------- | ------------------------------------------ |
| 30   | Primary   | Black/Dark Gray | Headers, section titles, primary information | `$(color 30 'Git Commands')`               |
| 31   | Error     | Red             | Critical errors, failed operations           | `message 31 "ERROR" "Operation failed"`    |
| 32   | Success   | Green           | Successful operations, completions           | `message 32 "SUCCESS" "Build completed"`   |
| 33   | Warning   | Yellow          | Warnings, cautions, important notices        | `message 33 "WARNING" "Updates available"` |
| 34   | Info      | Blue            | Informational messages, process updates      | `message 34 "INFO" "Processing..."`        |
| 35   | Debug     | Magenta         | Debug information, verbose output            | `message 35 "DEBUG" "Variable: $var"`      |
| 36   | Reference | Cyan            | URLs, paths, external references             | `message 36 "URL" "https://diseec.com"`    |

### Background Colors (40-49)

| Code | Type      | Color              | Usage                               | Example                                           |
| ---- | --------- | ------------------ | ----------------------------------- | ------------------------------------------------- |
| 40   | Header    | Black Background   | Major section headers               | `message 40 "v1.0.0" "DISEEC DevOps CLI"`         |
| 41   | Critical  | Red Background     | Critical alerts, severe errors      | `message 41 "CRITICAL" "System failure"`          |
| 42   | Success   | Green Background   | Major success confirmations         | `message 42 "COMPLETE" "Installation successful"` |
| 43   | Important | Yellow Background  | Important warnings, updates         | `message 43 "IMPORTANT" "Breaking changes"`       |
| 44   | Process   | Blue Background    | Active processes, status updates    | `message 44 "RUNNING" "Building images..."`       |
| 45   | Prompt    | Magenta Background | User prompts, interactive questions | `message 45 "?" "Continue? [y/N]"`                |
| 46   | Special   | Cyan Background    | Special notices, highlights         | `message 46 "NEW" "Feature available"`            |
| 47   | Brand     | White Background   | Brand elements, main banner         | `message 47 "DISEEC" "Enterprise DevOps Kit"`     |

## Usage Guidelines

### 1. Consistency Rules

**DO:**

- Use the same color code for the same type of message throughout
- Follow the established patterns for message types
- Use background colors for emphasis and important messages
- Maintain readability with sufficient contrast

**DON'T:**

- Mix color codes randomly without purpose
- Use background colors for routine messages
- Override established color meanings
- Use colors that are hard to read

### 2. Message Function Patterns

```bash
# Standard information
message 34 "INFO" "Starting process..."

# Success confirmation
message 32 "SUCCESS" "Operation completed"

# Warning with background emphasis
message 43 "WARNING" "Important update required"

# Error with context
message 31 "ERROR" "Failed to connect to service"

# User interaction
message 45 "?" "Select an option:"

# External reference
message 36 "URL" "https://github.com/diseec/kit"
```

### 3. Color Function in Help Systems

```bash
# Section headers in help
"$(color 30 'Command Category')"

# Usage examples
"$(color 32 '    cli command [options]')"

# Important notes
"$(color 34 'Note:')" "Additional information"
```

### 4. Status Indicators

```bash
# Process status
message 44 "BUILDING" "Creating Docker images..."
message 32 "BUILT" "Images created successfully"

# Git status
message 34 "GIT" "Checking branch status..."
message 36 "BRANCH" "main"

# Service status
message 34 "SERVICE" "Starting development environment..."
message 42 "READY" "All services running"
```

## Implementation Examples

### Command Help Systems

```bash
display_help \
    "" "" \
    "$(color 30 'Usage')" "" \
    "$(color 32 '    cli <command> [options]\n')" "" \
    "$(color 30 'Commands')" "" \
    "    install    " "Install project dependencies" \
    "    dev        " "Start development environment" \
    "" "" \
    "$(color 34 'Note:')" "Use 'cli help <command>' for detailed help"
```

### Progress Indicators

```bash
# Starting process
message 44 "INSTALLING" "Setting up dependencies..."

# Progress updates
message 34 "PROGRESS" "Downloaded 50/100 packages"

# Completion
message 42 "COMPLETE" "Installation finished successfully"
```

### Error Handling

```bash
# Warnings
message 33 "WARNING" "Configuration file not found, using defaults"

# Errors
message 31 "ERROR" "Unable to connect to Docker daemon"

# Critical issues
message 41 "CRITICAL" "System requirements not met"
```

### Interactive Prompts

```bash
# Yes/No questions
message 45 "?" "Continue with installation? [y/N]"

# Selection prompts
message 45 "SELECT" "Choose a workspace module:"

# Confirmation
message 45 "CONFIRM" "Delete all secrets? Type 'DELETE' to confirm:"
```

## Special Formatting

### Bold and Emphasis

```bash
# Bold text in messages
message 30 "TITLE" "\e[1mBold Title Text\e[0m"

# Underlined text
message 34 "INFO" "\e[4mUnderlined text\e[0m"
```

### Combining Colors

```bash
# Multiple colors in one message
printf "\e[1;30;47m DISEEC \e[0m"
color 34 " $(capitalize "info") "
printf " Message content\n"
```

## Accessibility Considerations

### Color-Blind Friendly

- **Avoid color-only information**: Always combine color with text/symbols
- **Test combinations**: Ensure sufficient contrast
- **Provide alternatives**: Use symbols alongside colors when possible

### Terminal Compatibility

```bash
# Check if terminal supports colors
if [ -t 1 ] && command -v tput >/dev/null && tput colors >/dev/null 2>&1; then
    # Use colors
    color 32 "Success message"
else
    # Fallback to plain text
    echo "Success message"
fi
```

## Testing Color Output

### Visual Test Script

```bash
#!/bin/bash
# test-colors.sh - Visual test of all color codes

echo "DISEEC DevOps Kit - Color Test"
echo "================================"

# Test text colors
echo "\nText Colors (30-39):"
for i in {30..39}; do
    printf "\e[${i}m Color $i: Sample text \e[0m\n"
done

# Test background colors
echo "\nBackground Colors (40-49):"
for i in {40..49}; do
    printf "\e[${i}m Color $i: Sample text \e[0m\n"
done

# Test message function
echo "\nMessage Function Examples:"
message 30 "PRIMARY" "Primary message"
message 31 "ERROR" "Error message"
message 32 "SUCCESS" "Success message"
message 33 "WARNING" "Warning message"
message 34 "INFO" "Info message"
message 35 "DEBUG" "Debug message"
message 36 "REFERENCE" "Reference message"

echo "\nBackground Message Examples:"
message 40 "v1.0.0" "Version banner"
message 41 "CRITICAL" "Critical alert"
message 42 "COMPLETE" "Success banner"
message 43 "IMPORTANT" "Important notice"
message 44 "PROCESS" "Process update"
message 45 "?" "User prompt"
message 46 "SPECIAL" "Special notice"
message 47 "BRAND" "Brand banner"
```

## Best Practices Summary

1. **Be Consistent**: Use the same colors for the same purposes
2. **Consider Context**: Background colors for emphasis, text colors for routine
3. **Test Readability**: Ensure colors work in different terminal themes
4. **Document Usage**: Comment your color choices in complex scripts
5. **Provide Fallbacks**: Handle terminals that don't support colors
6. **Follow Patterns**: Use established message patterns from this guide

## Reference Quick Card

```bash
# Quick reference for common patterns
ERROR:    message 31 "ERROR" "..."
SUCCESS:  message 32 "SUCCESS" "..."
WARNING:  message 33 "WARNING" "..."
INFO:     message 34 "INFO" "..."
PROMPT:   message 45 "?" "..."
URL:      message 36 "URL" "..."
HEADER:   message 40 "TITLE" "..."
```

This style guide ensures consistency across all CLI components and provides a professional, accessible user experience.
