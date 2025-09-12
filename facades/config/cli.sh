#!/bin/bash

source_once "$D_SDK_DIR/facades/config/index.sh"

# ========================================
# CONFIGURATION CLI INTEGRATION
# ========================================
# CLI interface for configuration management

# Ensure configuration is initialized
sdk_fac_con_init >/dev/null 2>&1

# Main configuration CLI handler

# Extract scope option from arguments and preserve remaining arguments
SCOPE="$DEFAULT_SCOPE"
FILTERED_ARGS=()
NEXT_IS_SCOPE=""

for arg in "$@"; do
    case "$arg" in
        -s=*|--scope=*) SCOPE="${arg#*=}" ;;
        -s|--scope)
            # Handle --scope as separate argument
            if [ "$NEXT_IS_SCOPE" = "true" ]; then
                SCOPE="$arg"
                NEXT_IS_SCOPE=""
            else
                NEXT_IS_SCOPE="true"
            fi
            ;;
        *)
            if [ "$NEXT_IS_SCOPE" = "true" ]; then
                SCOPE="$arg"
                NEXT_IS_SCOPE=""
            else
                FILTERED_ARGS+=("$arg")
            fi
            ;;
    esac
done

# Set arguments to filtered array
set -- "${FILTERED_ARGS[@]}"

c=$1; shift; case $c in
    # Basic operations
    ini|init) echo "Configuration already initialized" ;; # Initialization now happens automatically
    sum|summary) sdk_fac_con_summary "$@" ;;
    get) sdk_fac_con_get "$@" "$SCOPE" ;;
    set) sdk_fac_con_set "$1" "$2" "$SCOPE" ;;
    rem|remove) sdk_fac_con_delete "$1" "$2" "$SCOPE" ;;
    pat|path) sdk_fac_con_get_config_file "$SCOPE" ;;
    whi|which) sdk_fac_con_which "$@" ;;
    pri|print) sdk_fac_con_print "$@" ;;

    # Available settings
    sse|submodule_select) sdk_fac_con_set_act_select "$@" ;;
    sst|submodule_status) sdk_fac_con_set_act_status "$@" ;;

    hel|help|--help|-h) display_help "" "" \
    "$(ansi "1;90" "$(capitalize 'Configuration Management System')")" "" \
    "" "" "$(ansi "1;90" "$(capitalize 'Usage')")" "    config <command> [SCOPE_OPTIONS] [arguments]" \
    "" "" "$(ansi "1;90" "$(capitalize 'Available Settings')")" "" \
    "    $(ansi "1;2;90" "$(capitalize 'Submodule')")" "" \
    "    sse|submodule_select     " "Activate submodules for workspace" \
    "    sst|submodule_status     " "Show active submodules in workspace" \
    "" "" "$(ansi "1;90" "$(capitalize 'Basic Commands')")" "" \
    "    get                      " "Get configuration value with hierarchy resolution" \
    "                             " "$(ansi "2;90" "Example: get <key.path>")" \
    "    set                      " "Set configuration value" \
    "                             " "$(ansi "2;90" "Example: set <key.path> <value>")" \
    "                             " "$(ansi "2;90" "For arrays: set <key.path> \"[item1,item2,item3]\" (standard YAML array format)")" \
    "    rem|remove               " "Remove value from array or delete key (value optional)" \
    "                             " "$(ansi "2;90" "Example: remove <key.path> [value]")" \
    "    whi|which                " "Show configuration value resolution path (no scope needed)" \
    "                             " "$(ansi "2;90" "Example: which <key.path>")" \
    "    pat|path                 " "Show configuration path (no scope needed)" \
    "    pri|print                " "Print configuration for scope (or all if no scope)" \
    "    sta|status               " "Show configuration summary" \
    "    hel|help                 " "Show this help message" \
    "" "" "$(ansi "1;90" "$(capitalize 'Scope Options')")                " "$(ansi "2;90" "Mandatory for most commands")" \
    "    -s=<scope>               " "Set scope (short form)" \
    "    --scope=<scope>          " "Set scope (long form with equals)" \
    "    --scope <scope>          " "Set scope (long form with space)" \
    "" "" "    $(ansi "1;2;90" "$(capitalize 'Scopes')")" "" \
    "    context                  " "Project-specific shared configuration ($SCOPE_CTX_FILE)" \
    "    repository               " "Project-specific local configuration ($SCOPE_REPO_FILE)" \
    "    user                     " "User-specific configuration ($SCOPE_USER_FILE)" \
    "" "" "    $(ansi "1;2;90" "$(capitalize 'Hierarchy')")" "" \
    "    $(ansi "2;90" "Configuration values are resolved in this order of precedence:")" \
    "    $(ansi "2;90" "context > repository > user")" \
    "" "" "    $(ansi "1;2;90" "$(capitalize 'Examples')")" "" \
    "    $(ansi "2;90" "config --scope=context get context.submodules")" \
    "    $(ansi "2;90" "config -s=user set defaults.shell zsh")" \
    "    $(ansi "2;90" "config --scope context set context.submodules '[service1,service2,service3]'")" \
    "    $(ansi "2;90" "config --scope user set user.theme dark")" \
    "    $(ansi "2;90" "config which organization.name")" \
    "    $(ansi "2;90" "config --scope=context print")" \
    "    $(ansi "2;90" "config --scope context remove \"some.key\"")" \
    "$@"
    ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_ctx config help; exit 1;
        ;;
esac
