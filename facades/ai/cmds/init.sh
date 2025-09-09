#!/bin/bash
# AI Module - Init Command
# Initialize and validate AI module setup

# Initialize AI module with interactive setup
# Usage: sdk_fac_ai_cmd_init [--force]
sdk_fac_ai_cmd_init() {
    local force_flag=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --force|-f)
                force_flag=true
                ;;
            *)
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    logit -i "Initializing AI module..."
    
    # Check if already initialized and not forced
    if sdk_fac_ai_is_available && [ "$force_flag" != "true" ]; then
        logit -i "AI module is already initialized and available"
        logit -i "Use --force to re-initialize"
        return 0
    fi
    
    # Initialize interactively
    if sdk_fac_ai_init_interactive; then
        logit -s "AI module initialized successfully"
        
        # Test the connection
        local test_response
        test_response=$(sdk_fac_ai_generate "Say 'Hello from DISEEC AI'" "$FAC_AI_MODEL_GPT4o" "0.1" "Connection test failed")
        
        if [ $? -eq 0 ]; then
            logit -s "AI API connection test successful"
            logit -i "Response: $test_response"
        else
            logit -w "AI module initialized but connection test failed"
        fi
        
        return 0
    else
        logit -e "Failed to initialize AI module"
        logit -i "Make sure you have added OPENAI_API_KEY to secrets:"
        logit -i "  $D_CLI_GLOBAL_NAME secret add OPENAI_API_KEY"
        return 1
    fi
}
