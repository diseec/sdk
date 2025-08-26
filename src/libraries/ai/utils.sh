#!/bin/bash
# AI Module Utilities
# Helper functions for data processing and validation

# Escape a string for JSON
# Usage: ai_escape_json "string to escape"
# Output: JSON-escaped string
ai_escape_json() {
    local input="$1"
    echo "$input" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' '\r' | sed 's/\r/\\n/g'
}

# Extract content from OpenAI API response
# Usage: ai_extract_response "response_json"
# Output: Extracted content or original response if parsing fails
ai_extract_response() {
    local response="$1"
    
    # Try jq first (preferred method)
    if command -v jq >/dev/null 2>&1; then
        echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null
    else
        # Fallback to grep/sed if jq is not available
        echo "$response" | grep -o '"content":"[^"]*"' | sed 's/"content":"//g' | sed 's/"$//g' | sed 's/\\n/\n/g'
    fi
}

# Check if OpenAI API response contains an error
# Usage: ai_has_error "response_json"
# Returns: 0 if error found, 1 if no error
ai_has_error() {
    local response="$1"
    if echo "$response" | grep -q '"error"'; then
        return 0
    else
        return 1
    fi
}

# Generate fallback commit message when AI is not available
# Usage: ai_fallback_commit_message "files_changed"
# Output: Simple commit message based on file changes
ai_fallback_commit_message() {
    local files_changed="$1"
    local num_files=$(echo "$files_changed" | wc -l | tr -d ' ')
    local main_file=$(echo "$files_changed" | head -1)
    
    if [ "$num_files" -eq 1 ]; then
        echo "Update $main_file"
    else
        echo "Update $num_files files"
        echo ""
        echo "Modified files:"
        echo "$files_changed" | sed 's/^/- /'
    fi
}
