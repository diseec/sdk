#!/bin/bash
# AI Module API Client
# Handles direct communication with OpenAI API

# Make a generic OpenAI API call
# Usage: src_fac_ai_call_openai "prompt" "model" "temperature"
# Output: Raw API response
src_fac_ai_call_openai() {
    local prompt="$1"
    local model="${2:-$FAC_AI_MODEL_GPT4o}"
    local temperature="${3:-$FAC_AI_DEFAULT_TEMPERATURE}"
    local max_tokens="${4:-$FAC_AI_MAX_INPUT_TOKENS}"
    
    if ! src_fac_ai_is_available; then
        echo "ERROR: AI is not available (missing API key or curl)" >&2
        return 1
    fi
    
    # Ensure the prompt doesn't exceed token limit
    local token_count=$(src_fac_ai_count_tokens "$prompt")
    if [ "$token_count" -gt "$max_tokens" ]; then
        logit -w "Prompt exceeds token limit ($token_count > $max_tokens), truncating..." >&2
        prompt=$(src_fac_ai_truncate_to_token_limit "$prompt" "$max_tokens")
    fi
    
    local escaped_prompt=$(src_fac_ai_escape_json "$prompt")
    
    curl -s "$FAC_AI_API_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"$escaped_prompt\"}], \"temperature\": $temperature}"
}

# Generate a completion using AI with error handling
# Usage: src_fac_ai_generate "prompt" "model" "temperature" "fallback_message" "max_tokens"
# Output: AI-generated content or fallback message
src_fac_ai_generate() {
    local prompt="$1"
    local model="${2:-$FAC_AI_MODEL_GPT4o}"
    local temperature="${3:-$FAC_AI_DEFAULT_TEMPERATURE}"
    local fallback="${4:-Error: Failed to generate AI response}"
    local max_tokens="${5:-$FAC_AI_MAX_INPUT_TOKENS}"
    
    if ! src_fac_ai_is_available; then
        echo "$fallback"
        return 1
    fi
    
    # Check token count for logging
    local token_count=$(src_fac_ai_count_tokens "$prompt")
    echo "Sending prompt with ~$token_count tokens to model $model" >&2
    
    local response=$(src_fac_ai_call_openai "$prompt" "$model" "$temperature" "$max_tokens")
    
    if src_fac_ai_has_error "$response"; then
        logit -e "OpenAI API error occurred" >&2
        echo "$fallback"
        return 1
    fi
    
    local content=$(src_fac_ai_extract_response "$response")
    
    if [ -n "$content" ] && [ "$content" != "null" ]; then
        echo "$content"
        return 0
    else
        logit -e "Failed to extract content from AI response" >&2
        echo "$fallback"
        return 1
    fi
}
