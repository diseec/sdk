#!/bin/bash
# AI Module Configuration
# Handles initialization, configuration constants, and availability checks

# AI configuration constants
export FAC_AI_MODEL_GPT35="gpt-3.5-turbo"
export FAC_AI_MODEL_GPT4="gpt-4"
export FAC_AI_MODEL_GPT4o="gpt-4o-mini"
export FAC_AI_DEFAULT_TEMPERATURE="0.3"
export FAC_AI_CREATIVE_TEMPERATURE="0.7"
export FAC_AI_API_ENDPOINT="https://api.openai.com/v1/chat/completions"

# Initialize AI module and validate API key
# Returns: 0 if successful, 1 if failed
fac_ai_init() {
    if fac_sec_validate_and_prepare_secret "OPENAI_API_KEY"; then
        export OPENAI_API_KEY="$(fac_sec_export OPENAI_API_KEY)"
        return 0
    else
        message 31 "ERROR" "Unable to prepare secret 'OPENAI_API_KEY' for export" >&2
        return 1
    fi
}

# Check if AI is available (API key and curl)
# Returns: 0 if available, 1 if not
fac_ai_is_available() {
    if command -v curl >/dev/null 2>&1 && [ -n "$OPENAI_API_KEY" ]; then
        return 0
    else
        return 1
    fi
}
