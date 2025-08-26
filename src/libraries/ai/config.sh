#!/bin/bash
# AI Module Configuration
# Handles initialization, configuration constants, and availability checks

# AI configuration constants
export AI_MODEL_GPT35="gpt-3.5-turbo"
export AI_MODEL_GPT4="gpt-4"
export AI_MODEL_GPT4o="gpt-4o-mini"
export AI_DEFAULT_TEMPERATURE="0.3"
export AI_CREATIVE_TEMPERATURE="0.7"
export AI_API_ENDPOINT="https://api.openai.com/v1/chat/completions"

# Initialize AI module and validate API key
# Returns: 0 if successful, 1 if failed
ai_init() {
    if validate_and_prepare_secret "OPENAI_API_KEY"; then
        export OPENAI_API_KEY="$(cmd_secret_export OPENAI_API_KEY)"
        return 0
    else
        message 31 "ERROR" "Unable to prepare secret 'OPENAI_API_KEY' for export" >&2
        return 1
    fi
}

# Check if AI is available (API key and curl)
# Returns: 0 if available, 1 if not
ai_is_available() {
    if command -v curl >/dev/null 2>&1 && [ -n "$OPENAI_API_KEY" ]; then
        return 0
    else
        return 1
    fi
}
