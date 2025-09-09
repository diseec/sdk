#!/bin/bash
# AI Module - Availability Command
# Check if AI services are available

# Check AI availability and display status
# Usage: sdk_fac_ai_cmd_check_availability [--quiet]
sdk_fac_ai_cmd_check_availability() {
    local quiet_flag=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --quiet|-q)
                quiet_flag=true
                ;;
            *)
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if [ "$quiet_flag" != "true" ]; then
        logit -i "Checking AI availability..."
    fi
    
    # Use the existing availability check function
    if sdk_fac_ai_is_available; then
        if [ "$quiet_flag" != "true" ]; then
            logit -s "AI services are available"
            logit -i "API Endpoint: $FAC_AI_API_ENDPOINT"
            logit -i "Default Model: $FAC_AI_MODEL_GPT4o"
            if [ -n "$OPENAI_API_KEY" ]; then
                logit -i "API Key: ${OPENAI_API_KEY:0:8}...${OPENAI_API_KEY: -4}"
            fi
        fi
        return 0
    else
        if [ "$quiet_flag" != "true" ]; then
            # Check what's missing
            if ! command -v curl >/dev/null 2>&1; then
                logit -e "curl command not found - required for AI API calls"
            elif [ -z "$OPENAI_API_KEY" ]; then
                logit -e "OPENAI_API_KEY not found in environment or secrets"
                logit -i "Add API key with: $D_CLI_GLOBAL_NAME secret add OPENAI_API_KEY"
                logit -i "Or initialize AI module with: $D_CLI_GLOBAL_NAME ai init"
            else
                logit -e "AI services are not available"
            fi
        fi
        return 1
    fi
}
