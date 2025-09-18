#!/bin/bash
# AI Module Generators
# High-level AI content generation functions

# Generate a commit message from git diff data
# Usage: sdk_fac_ai_generate_commit_message "diff_summary" "diff_preview"
# Output: AI-generated commit message
sdk_fac_ai_generate_commit_message() {
    local diff_summary_file="$1"
    local diff_preview_file="$2"
    if [ ! -f "$diff_summary_file" ] || [ ! -f "$diff_preview_file" ]; then
        stdout -e "Diff summary or preview file does not exist"
        return 1
    fi
    # Read contents from files using cat
    local diff_summary=$(cat "$diff_summary_file")
    local diff_preview=$(cat "$diff_preview_file")

    # Check token count and truncate if necessary
    local token_count=$(sdk_fac_ai_count_tokens "$diff_summary")
    if [ "$token_count" -gt "$FAC_AI_MAX_INPUT_TOKENS" ]; then
        stdout -w "Diff summary exceeds token limit ($token_count tokens), truncating..." >&2
        # use half of max tokens for summary and half for preview
        diff_summary=$(sdk_fac_ai_truncate_to_token_limit "$diff_summary" "$FAC_AI_MAX_INPUT_TOKENS/2")
    fi
    token_count=$(sdk_fac_ai_count_tokens "$diff_preview")
    if [ "$token_count" -gt "$FAC_AI_MAX_INPUT_TOKENS" ]; then
        stdout -w "Diff preview exceeds token limit ($token_count tokens), truncating..." >&2
        diff_preview=$(sdk_fac_ai_truncate_to_token_limit "$diff_preview" "$FAC_AI_MAX_INPUT_TOKENS/2")
    fi

    if [ -z "$diff_summary" ] || [ -z "$diff_preview" ]; then
        stdout -e "Missing diff summary or preview for commit message generation"
        return 1
    fi

    stdin work_focus "What was main changes?"

    local prompt="Generate a concise, descriptive commit message for the following code changes.
User commit message:
$work_focus

Summary of changes:
$diff_summary

Preview of changes:
$diff_preview

Please format the response as a commit message with a short title (max 50 chars) on the first line, then a blank line, then bullet points with details if needed."

    sdk_fac_ai_generate "$prompt" "$FAC_AI_MODEL_GPT4o" "$FAC_AI_CREATIVE_TEMPERATURE" "Update files"
}

# Generate a daily development insight report
# Usage: sdk_fac_ai_generate_daily_insight "analysis_data"
# Output: AI-generated insight report
sdk_fac_ai_generate_daily_insight() {
    local analysis_data_file="$1"
    if [ ! -f "$analysis_data_file" ]; then
        stdout -e "Analysis data file does not exist"
        return 1
    fi
    # Read contents from file using cat
    local analysis_data=$(cat "$analysis_data_file")

    if [ -z "$analysis_data" ]; then
        stdout -e "Missing analysis data for daily insight generation"
        return 1
    fi
    
    # Check token count and truncate if necessary
    local token_count=$(sdk_fac_ai_count_tokens "$analysis_data")
    if [ "$token_count" -gt "$FAC_AI_MAX_INPUT_TOKENS" ]; then
        stdout -w "Analysis data exceeds token limit ($token_count tokens), truncating..." >&2
        analysis_data=$(sdk_fac_ai_truncate_to_token_limit "$analysis_data" "$FAC_AI_MAX_INPUT_TOKENS")
    fi
    
    local prompt="Analyze the following development activity and create a concise daily insight report.

$analysis_data

Please format the response as:
1. A single descriptive title that captures the overall view of changes
2. A bulleted list of key deliverables and values added (focus on CRITICAL to MEDIUM level changes)
3. Each bullet should start with '-' and mention specific files/repositories when relevant
4. Focus on: new features, bug fixes, refactoring, performance improvements, security enhancements
5. Keep descriptions brief but informative
6. No empty lines between bullets
7. Do NOT use any Markdown formatting (no **bold**, no headings, no code blocks, no lists with *, no backticks, etc.)

Example format:
Enhanced Authentication and Performance Optimizations
- Fixed critical authentication bug 'bug name' in path/to/file.js affecting login flow
- Added new user dashboard feature 'feature name' in path/to/file.tsx
- Refactored database connection pooling in path/to/file.js for 40% performance improvement
- Updated security headers configuration in nginx.conf
- Optimized API response caching in path/to/dir"
    
    sdk_fac_ai_generate "$prompt" "$FAC_AI_MODEL_GPT4o" "$FAC_AI_DEFAULT_TEMPERATURE" "No insights available" "$FAC_AI_MAX_INPUT_TOKENS"
}
