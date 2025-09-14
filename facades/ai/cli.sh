#!/bin/bash

source_once "$D_SDK_DIR/facades/ai/index.sh"

# AI Module - Abstracted AI operations for the SDK
# Provides AI-powered automation features using OpenAI API

# prevent multiple initializations
_FAC_AI_INITIALIZED=1
if [ -n "$_FAC_AI_INITIALIZED" ]; then
    sdk_fac_ai_init_interactive
fi

c=$1; shift; case $c in
    ava|available)
        mark_ctx_only
        sdk_fac_ai_cmd_check_availability "$@"
        ;;
    gen|generate)
        c=$1; shift; case $c in
            com|commit)
                mark_ctx_only
                sdk_fac_ai_generate_commit_message "$@"
                ;;
            ins|insight)
                mark_ctx_only
                sdk_fac_ai_generate_daily_insight "$@"
                ;;
            hel|help|--help|-h)
                display_help \
                    "" "" "$(ansi "1;90" "$(capitalize 'AI Generate Commands')")" "" \
                    "$(ansi 97 'Usage:    cli ai generate <command> [options]')" "" "" "" \
                    "    com|commit           " "Generate commit message from staged changes" \
                    "    ins|insight          " "Generate development insights from git logs" \
                    "$@"
                ;;
            *)
                if [[ -n "$c" ]]; then logit -e "Unknown generate command: '$c'"; fi
                cli_ctx ai $c help
                return 1
                ;;
        esac
        ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi "1;90" "$(capitalize 'Usage')")                      " "[$D_CLI_GLOBAL_NAME ai]/[bash $D_CLI_LOCAL_NAME ai] [command] [subcommand] [options]" \
            "                           " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$D_ORG_NAME/$D_SDK_NAME")")" \
            "" "" "$(ansi "1;90" "$(capitalize 'AI Commands - AI-Powered Development Automation')")" "" \
            "" "" "$(ansi "1;90" "$(capitalize 'Core Commands')")" "" \
            "    ava|available          " "Check if AI services are available" \
            "" "" "$(ansi "1;90" "$(capitalize 'Content Generation')")" "" \
            "    gen|generate           " "Generate AI content" \
            "        com|commit         " "$(ansi "2;90" "Generate commit message from git changes")" \
            "        ins|insight        " "$(ansi "2;90" "Generate development insights")" \
            "" "" \
            "" "$(ansi "2;90" "SETUP REQUIRED: Add OpenAI API key for AI features: $D_CLI_GLOBAL_NAME secret add OPENAI_API_KEY")" \
            "$@"
        ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_ctx ai help; return 1;
        ;;
esac
