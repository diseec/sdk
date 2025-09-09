#!/bin/bash
# AI Module Generators
# High-level AI content generation functions

# Generate a commit message from git diff data
# Usage: sdk_fac_ai_generate_commit_message "diff_summary" "diff_preview"
# Output: AI-generated commit message
sdk_fac_ai_generate_commit_message() {
    local diff_summary="$1"
    local diff_preview="$2"
    
    # Load the commit prompt template
    local prompt_template
    prompt_template=$(sdk_fac_ai_prompt_load "commit")
    
    if [ $? -ne 0 ]; then
        # Fallback to inline prompt if template not found
        prompt_template="Generate a concise, descriptive commit message for the following code changes.

Summary of changes:
{{DIFF_SUMMARY}}

Preview of changes:
{{DIFF_PREVIEW}}

Please format the response as a commit message with a short title (max 50 chars) on the first line, then a blank line, then bullet points with details if needed."
    fi
    
    # Replace placeholders
    local prompt=$(sdk_fac_ai_prompt_replace_placeholders "$prompt_template" \
        "DIFF_SUMMARY=$diff_summary" \
        "DIFF_PREVIEW=$diff_preview")
    
    sdk_fac_ai_generate "$prompt" "$FAC_AI_MODEL_GPT4o" "$FAC_AI_CREATIVE_TEMPERATURE" "Update files"
}

# Generate a daily development insight report
# Usage: sdk_fac_ai_generate_daily_insight "analysis_data"
# Output: AI-generated insight report
sdk_fac_ai_generate_daily_insight() {
    local analysis_data="$1"
    
    # Check token count and truncate if necessary
    local token_count=$(sdk_fac_ai_count_tokens "$analysis_data")
    if [ "$token_count" -gt "$FAC_AI_MAX_INPUT_TOKENS" ]; then
        echo "Analysis data exceeds token limit ($token_count tokens), truncating..." >&2
        analysis_data=$(sdk_fac_ai_truncate_to_token_limit "$analysis_data" "$FAC_AI_MAX_INPUT_TOKENS")
    fi
    
    # Load the daily insight prompt template
    local prompt_template
    prompt_template=$(sdk_fac_ai_prompt_load "daily-insight")
    
    if [ $? -ne 0 ]; then
        # Fallback to inline prompt if template not found
        prompt_template="Analyze the following development activity and create a concise daily insight report.

{{INPUT}}

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
- Fixed critical authentication bug X in user-service/auth.js affecting login flow
- Added new user dashboard feature X in frontend/components/Dashboard.tsx
- Refactored database connection pooling in api/database.js for 40% performance improvement
- Updated security headers configuration in nginx.conf
- Optimized API response caching in services/cache-service"
    fi
    
    # Replace placeholders
    local prompt=$(sdk_fac_ai_prompt_replace_placeholders "$prompt_template" \
        "INPUT=$analysis_data")
    
    sdk_fac_ai_generate "$prompt" "$FAC_AI_MODEL_GPT4o" "$FAC_AI_DEFAULT_TEMPERATURE" "No insights available" "$FAC_AI_MAX_INPUT_TOKENS"
}
