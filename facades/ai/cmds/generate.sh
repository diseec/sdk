#!/bin/bash
# AI Module - Generate Commands
# Content generation commands using AI

# Generate commit message from staged changes
# Usage: sdk_fac_ai_cmd_generate_commit [--model=<model>] [--temperature=<temp>]
sdk_fac_ai_cmd_generate_commit() {
    local model="$FAC_AI_MODEL_GPT4o"
    local temperature="$FAC_AI_DEFAULT_TEMPERATURE"
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --model=*)
                model="${arg#*=}"
                ;;
            --temperature=*)
                temperature="${arg#*=}"
                ;;
            *)
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if ! sdk_fac_ai_is_available; then
        logit -e "AI services not available. Run: $D_CLI_GLOBAL_NAME ai init"
        return 1
    fi
    
    # Get git diff information
    local diff_summary diff_preview files_changed
    diff_summary=$(git diff --cached --stat 2>/dev/null | head -10)
    diff_preview=$(git diff --cached --no-color 2>/dev/null | head -50)
    files_changed=$(git diff --cached --name-only 2>/dev/null)
    
    if [ -z "$diff_summary" ] && [ -z "$files_changed" ]; then
        logit -e "No staged changes found. Stage your changes with 'git add' first."
        return 1
    fi
    
    # Generate commit message
    local commit_message
    commit_message=$(sdk_fac_ai_generate_commit_message "$diff_summary" "$diff_preview")
    
    if [ $? -eq 0 ] && [ -n "$commit_message" ]; then
        echo "$commit_message"
        return 0
    else
        # Fallback to simple commit message
        logit -w "AI generation failed, using fallback"
        sdk_fac_ai_fallback_commit_message "$files_changed"
        return 1
    fi
}

# Generate development insights from analysis data
# Usage: sdk_fac_ai_cmd_generate_insight [--model=<model>] [--input=<file>]
sdk_fac_ai_cmd_generate_insight() {
    local model="$FAC_AI_MODEL_GPT4o"
    local input_file=""
    local analysis_data=""
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --model=*)
                model="${arg#*=}"
                ;;
            --input=*)
                input_file="${arg#*=}"
                ;;
            *)
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if ! sdk_fac_ai_is_available; then
        logit -e "AI services not available. Run: $D_CLI_GLOBAL_NAME ai init"
        return 1
    fi
    
    # Get analysis data
    if [ -n "$input_file" ] && [ -f "$input_file" ]; then
        analysis_data=$(cat "$input_file")
    else
        # Get from stdin or generate from git logs
        if [ -t 0 ]; then
            # Generate from recent git activity
            analysis_data=$(git log --oneline --since="24 hours ago" --pretty=format:"%h %s" 2>/dev/null | head -20)
            if [ -z "$analysis_data" ]; then
                logit -e "No recent git activity found and no input provided"
                return 1
            fi
        else
            analysis_data=$(cat)
        fi
    fi
    
    if [ -z "$analysis_data" ]; then
        logit -e "No analysis data provided"
        return 1
    fi
    
    # Generate insight
    local insight
    insight=$(sdk_fac_ai_generate_daily_insight "$analysis_data")
    
    if [ $? -eq 0 ] && [ -n "$insight" ]; then
        echo "$insight"
        return 0
    else
        logit -e "Failed to generate insights"
        return 1
    fi
}

# Generate content using a custom prompt
# Usage: sdk_fac_ai_cmd_generate_with_prompt <prompt_name> [--model=<model>] [--temperature=<temp>] [--input=<data>]
sdk_fac_ai_cmd_generate_with_prompt() {
    local prompt_name="$1"
    shift
    
    if [ -z "$prompt_name" ]; then
        logit -e "Prompt name required"
        logit -i "Usage: ai generate prompt <prompt_name> [options]"
        return 1
    fi
    
    local model="$FAC_AI_MODEL_GPT4o"
    local temperature="$FAC_AI_DEFAULT_TEMPERATURE"
    local input_data=""
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --model=*)
                model="${arg#*=}"
                ;;
            --temperature=*)
                temperature="${arg#*=}"
                ;;
            --input=*)
                input_data="${arg#*=}"
                ;;
            *)
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if ! sdk_fac_ai_is_available; then
        logit -e "AI services not available. Run: $D_CLI_GLOBAL_NAME ai init"
        return 1
    fi
    
    # Load prompt
    local prompt_content
    prompt_content=$(sdk_fac_ai_prompt_load "$prompt_name")
    
    if [ $? -ne 0 ] || [ -z "$prompt_content" ]; then
        logit -e "Prompt '$prompt_name' not found"
        logit -i "List available prompts with: ai prompt list"
        return 1
    fi
    
    # Replace placeholders in prompt if input data provided
    if [ -n "$input_data" ]; then
        prompt_content=$(echo "$prompt_content" | sed "s/{{INPUT}}/$input_data/g")
    fi
    
    # Generate content
    local result
    result=$(sdk_fac_ai_generate "$prompt_content" "$model" "$temperature")
    
    if [ $? -eq 0 ] && [ -n "$result" ]; then
        echo "$result"
        return 0
    else
        logit -e "Failed to generate content with prompt '$prompt_name'"
        return 1
    fi
}
