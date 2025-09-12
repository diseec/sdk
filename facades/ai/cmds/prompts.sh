#!/bin/bash
# AI Module - Prompt Management Commands
# Manage custom prompts for AI content generation

# List available prompts
# Usage: sdk_fac_ai_cmd_prompt_list [--verbose]
sdk_fac_ai_cmd_prompt_list() {
    local verbose_flag=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --verbose|-v)
                verbose_flag=true
                ;;
            *)
                logit -e "sdk_fac_ai_cmd_prompt_list: Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    local prompt_dir="$D_SDK_DIR/facades/ai/prompts"
    
    if [ ! -d "$prompt_dir" ]; then
        logit -w "No prompts directory found"
        return 1
    fi
    
    local prompts_found=false
    
    echo "Available AI Prompts:"
    echo "===================="
    
    for prompt_file in "$prompt_dir"/*.prompt; do
        if [ -f "$prompt_file" ]; then
            prompts_found=true
            local prompt_name=$(basename "$prompt_file" .prompt)
            
            if [ "$verbose_flag" = "true" ]; then
                local description=$(head -n 1 "$prompt_file" | sed 's/^# //')
                printf "  %-20s %s\n" "$prompt_name" "$description"
            else
                echo "  $prompt_name"
            fi
        fi
    done
    
    if [ "$prompts_found" = "false" ]; then
        echo "  No prompts found"
        echo ""
        echo "Add prompts with: ai prompt add <name> <file>"
    fi
}

# Show prompt content
# Usage: sdk_fac_ai_cmd_prompt_show <prompt_name>
sdk_fac_ai_cmd_prompt_show() {
    local prompt_name="$1"
    
    if [ -z "$prompt_name" ]; then
        logit -e "Prompt name required"
        return 1
    fi
    
    local prompt_content
    prompt_content=$(sdk_fac_ai_prompt_load "$prompt_name")
    
    if [ $? -ne 0 ]; then
        logit -e "Prompt '$prompt_name' not found"
        return 1
    fi
    
    echo "Prompt: $prompt_name"
    echo "=================="
    echo "$prompt_content"
}

# Add new prompt from file
# Usage: sdk_fac_ai_cmd_prompt_add <prompt_name> <source_file>
sdk_fac_ai_cmd_prompt_add() {
    local prompt_name="$1"
    local source_file="$2"
    
    if [ -z "$prompt_name" ] || [ -z "$source_file" ]; then
        logit -e "Prompt name and source file required"
        logit -i "Usage: ai prompt add <name> <file>"
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        logit -e "Source file '$source_file' not found"
        return 1
    fi
    
    local prompt_dir="$D_SDK_DIR/facades/ai/prompts"
    local prompt_file="$prompt_dir/${prompt_name}.prompt"
    
    # Create prompts directory if it doesn't exist
    mkdir -p "$prompt_dir"
    
    # Check if prompt already exists
    if [ -f "$prompt_file" ]; then
        logit -w "Prompt '$prompt_name' already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            logit -i "Cancelled"
            return 0
        fi
    fi
    
    # Copy the file
    if cp "$source_file" "$prompt_file"; then
        logit -s "Prompt '$prompt_name' added successfully"
        return 0
    else
        logit -e "Failed to add prompt '$prompt_name'"
        return 1
    fi
}
