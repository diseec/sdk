#!/bin/bash

source_once "$D_SDK_DIR/facades/ai/index.sh"

# AI Module - Abstracted AI operations for the SDK
# Provides AI-powered automation features using OpenAI API

c=$1; shift; case $c in
    ava|available)
        mark_ctx_only
        sdk_fac_ai_cmd_check_availability "$@"
        ;;
    ini|init)
        mark_ctx_only
        sdk_fac_ai_cmd_init "$@"
        ;;
    gen|generate)
        mark_ctx_only
        c=$1; shift; case $c in
            com|commit)
                sdk_fac_ai_cmd_generate_commit "$@"
                ;;
            ins|insight)
                sdk_fac_ai_cmd_generate_insight "$@"
                ;;
            pro|prompt)
                sdk_fac_ai_cmd_generate_with_prompt "$@"
                ;;
            *)
                if [[ -n "$c" ]]; then logit -e "Unknown generate command: '$c'"; fi
                cli_ctx ai help generate
                exit 1
                ;;
        esac
        ;;
    pro|prompt)
        mark_ctx_only
        c=$1; shift; case $c in
            lis|list)
                sdk_fac_ai_cmd_prompt_list "$@"
                ;;
            sho|show)
                sdk_fac_ai_cmd_prompt_show "$@"
                ;;
            add)
                sdk_fac_ai_cmd_prompt_add "$@"
                ;;
            *)
                if [[ -n "$c" ]]; then logit -e "Unknown prompt command: '$c'"; fi
                cli_ctx ai help prompt
                exit 1
                ;;
        esac
        ;;
    hel|help|--help|-h)
        c=$1; shift; case $c in
            generate)
                display_help "" "" \
                    "$(ansi "1;90" "$(capitalize 'AI Generate Commands')")" "" \
                    "$(ansi 97 'Usage:    cli ai generate <command> [options]')" "" "" "" \
                    "    com|commit           " "Generate commit message from staged changes" \
                    "    ins|insight          " "Generate development insights from git logs" \
                    "    pro|prompt <name>    " "Generate content using custom prompt" \
                    "$@"
                ;;
            prompt)
                display_help "" "" \
                    "$(ansi "1;90" "$(capitalize 'AI Prompt Management')")" "" \
                    "$(ansi 97 'Usage:    cli ai prompt <command> [options]')" "" "" "" \
                    "    lis|list             " "List available prompts" \
                    "    sho|show <name>      " "Show prompt content" \
                    "    add <name> <file>    " "Add new prompt from file" \
                    "$@"
                ;;
            *)
                display_help "" "" \
                    "$(ansi "1;90" "$(capitalize 'Usage')")" "[$D_CLI_GLOBAL_NAME ai]/[bash $D_CLI_LOCAL_NAME ai] [command] [subcommand] [options]" \
                    "                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$D_ORG_NAME/$D_SDK_NAME")")" \
                    "" "" "$(ansi "1;90" "$(capitalize 'AI Commands - AI-Powered Development Automation')")" "" \
                    "" "" "$(ansi "1;90" "$(capitalize 'Core Commands')")" "" \
                    "    ava|available        " "Check if AI services are available" \
                    "    ini|init             " "Initialize AI module with API key" \
                    "" "" "$(ansi "1;90" "$(capitalize 'Content Generation')")" "" \
                    "    gen|generate         " "Generate AI content" \
                    "        com|commit       " "$(ansi "2;90" "Generate commit message from git changes")" \
                    "        ins|insight      " "$(ansi "2;90" "Generate development insights")" \
                    "        pro|prompt <name>" "$(ansi "2;90" "Generate with custom prompt")" \
                    "" "" "$(ansi "1;90" "$(capitalize 'Prompt Management')")" "" \
                    "    pro|prompt           " "Manage custom prompts" \
                    "        lis|list         " "$(ansi "2;90" "List available prompts")" \
                    "        sho|show <name>  " "$(ansi "2;90" "Show prompt content")" \
                    "        add <name> <file>" "$(ansi "2;90" "Add new prompt from file")" \
                    "" "" "$(ansi "1;90" "$(capitalize 'Setup Required')")" "" \
                    "    $D_CLI_GLOBAL_NAME secret add OPENAI_API_KEY" "Add OpenAI API key for AI features" \
                    "    $D_CLI_GLOBAL_NAME ai init       " "Initialize and validate AI setup" \
                    "$@"
                ;;
        esac
        ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_ctx ai help; exit 1;
        ;;
esac
