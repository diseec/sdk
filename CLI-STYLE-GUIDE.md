# CLI Style Guide for Color Codes

## Overview
This document outlines the standardized color codes used in the DevOps CLI message function. The color codes are used to indicate different types of messages and status updates to provide a consistent visual experience.

## Color Code Ranges
- Text Colors (30-39): Basic text colors
- Background Colors (40-49): Filled background colors
- Special Effects: Combine with above for specific styling needs

## Message Types and Color Codes

### Status Indicators

| Code | Type        | Color Description           | Usage                                      |
|------|-------------|-----------------------------|--------------------------------------------|
| 30   | Info/Normal | Black text                  | Generic information, normal operations     |
| 31   | Error       | Red text                    | Critical errors, failed operations         |
| 32   | Success     | Green text                  | Successful operations, completions         |
| 33   | Warning     | Yellow text                 | Warnings, cautions, important notices      |
| 34   | Info/Action | Blue text                   | Actions being taken, informational messages|
| 35   | Debug       | Magenta text                | Debug information, verbose output          |
| 36   | URL/Path    | Cyan text                   | URLs, file paths, important references     |

### Background Colors (Filled)

| Code | Type          | Color Description           | Usage                                      |
|------|---------------|-----------------------------|--------------------------------------------|
| 40   | Header        | Black background            | Section headers, titles                    |
| 41   | Error         | Red background              | Critical errors, alerts                    |
| 42   | Success       | Green background            | Success confirmations                      |
| 43   | Warning       | Yellow background           | Important warnings, update notices         |
| 44   | Info/Process  | Blue background             | Process information, status updates        |
| 45   | Prompt/Query  | Magenta background          | User prompts, questions                    |
| 46   | Special       | Cyan background             | Special notices, high-priority information |
| 47   | Default       | White background            | Default brand banner                       |

## Examples

```bash
# Standard information message
message 34 "info" "Running task..."

# Success message
message 32 "success" "Task completed successfully"

# Error message
message 31 "error" "Operation failed"

# Warning with background color
message 43 "WARNING" "Updates available"

# User prompt
message 45 "?" "Please select an option"

# URL reference
message 36 "url" "https://github.com/diseec"
```

## Implementation Guidelines

1. Be consistent with message types - use the same color code for the same type of message
2. Use background colors (40-49) for emphasized messages that should stand out
3. Use text colors (30-39) for regular informational messages
4. Avoid using random color codes - follow this guide for all new messages

For detailed ANSI color code reference: https://en.wikipedia.org/wiki/ANSI_escape_code
