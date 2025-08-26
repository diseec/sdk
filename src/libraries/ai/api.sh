#!/bin/bash
# AI Module API Client
# Handles direct communication with OpenAI API

# Make a generic OpenAI API call
# Usage: ai_call_openai "prompt" "model" "temperature"
# Output: Raw API response
ai_call_openai() {
    local prompt="$1"
    local model="${2:-$AI_MODEL_GPT4o}"
    local temperature="${3:-$AI_DEFAULT_TEMPERATURE}"
    
    if ! ai_is_available; then
        echo "ERROR: AI is not available (missing API key or curl)" >&2
        return 1
    fi
    
    local escaped_prompt=$(ai_escape_json "$prompt")
    
    curl -s "$AI_API_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}], \"temperature\": $temperature}"
}

# Generate a completion using AI with error handling
# Usage: ai_generate "prompt" "model" "temperature" "fallback_message"
# Output: AI-generated content or fallback message
ai_generate() {
    local prompt="$1"
    local model="${2:-$AI_MODEL_GPT4o}"
    local temperature="${3:-$AI_DEFAULT_TEMPERATURE}"
    local fallback="${4:-Error: Failed to generate AI response}"
    
    if ! ai_is_available; then
        echo "$fallback"
        return 1
    fi
    
    local response=$(ai_call_openai "$prompt" "$model" "$temperature")
    
    if ai_has_error "$response"; then
        message 31 "ERROR" "OpenAI API error occurred" >&2
        echo "$fallback"
        return 1
    fi
    
    local content=$(ai_extract_response "$response")
    
    if [ -n "$content" ] && [ "$content" != "null" ]; then
        echo "$content"
        return 0
    else
        message 31 "ERROR" "Failed to extract content from AI response" >&2
        echo "$fallback"
        return 1
    fi
}
