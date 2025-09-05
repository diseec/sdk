#!/bin/bash

source_once "$D_SDK_DIR/facades/config/index.sh"

# ========================================
# CONFIGURATION CLI INTEGRATION
# ========================================
# CLI interface for configuration management

# Main configuration CLI handler

# Extract scope option from arguments
SCOPE=""
ARGS=""
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
                ARGS="$ARGS \"$arg\""
            fi
            ;;
    esac
done

# Reconstruct arguments without scope option
eval set -- $(eval echo $ARGS)

c=$1; shift; case $c in
    # Basic operations
    ini|init) sdk_fac_con_opt_act_init "$@" ;;
    sum|summary) sdk_fac_con_opt_act_status "$@" ;;
    get) sdk_fac_con_get "$@" "$SCOPE" ;;
    set) sdk_fac_con_set "$@" "$SCOPE" ;;
    add) sdk_fac_con_array_add "$@" "$SCOPE" ;;
    rem|remove) sdk_fac_con_array_remove "$@" "$SCOPE" ;;
    del|delete) sdk_fac_con_delete "$@" "$SCOPE" ;;
    pat|path) sdk_fac_con_get_config_file "$SCOPE" ;;
    whi|which) sdk_fac_con_which "$@" ;;
    pri|print) 
        # Print can work without scope (prints all scopes) or with scope
        if [ -n "$SCOPE" ]; then sdk_fac_con_print "$@" "$SCOPE"
        else sdk_fac_con_print "$@"; fi
    ;;

    # Available settings
    ssu|select_submodule) sdk_fac_con_opt_act_select "$@" ;;

    hel|help|--help|-h) display_help "" "" \
        "$(ansi 97 'Configuration Management System')" "" \
        "" "" "$(ansi 97 'Usage:    config [SCOPE_OPTIONS] <command> [arguments]')" "" \
        "$(ansi 97 'Scope Options (mandatory for most commands)')" "" \
        "    -s=<scope>               " "Set scope (short form)" \
        "    --scope=<scope>          " "Set scope (long form with equals)" \
        "    --scope <scope>          " "Set scope (long form with space)" \
        "" "" "$(ansi 97 'Available Settings')" "" \
        "    ssu|select_submodule     " "Activate submodules for workspace" \
        "" "" "$(ansi 97 'Basic Commands')" "" \
        "    get <key.path>           " "Get configuration value with hierarchy resolution" \
        "    set <key.path> <value>   " "Set configuration value in specified scope" \
        "    add <key.path> <value>   " "Add value to configuration array" \
        "    rem|remove <key.path> <val>" "Remove value from configuration array" \
        "    del|delete <key.path>    " "Delete configuration key from specified scope" \
        "    whi|which <key.path>     " "Show configuration value resolution path (no scope needed)" \
        "    pat|path                 " "Show configuration path (no scope needed)" \
        "    pri|print                " "Print configuration for scope (or all if no scope)" \
        "    sta|status               " "Show configuration summary" \
        "    hel|help                 " "Show this help message" \
        "" "" "$(ansi 97 'Scopes')" "" \
        "    work                     " "Project-specific shared configuration ($SCOPE_WORK_FILE)" \
        "    repo                     " "Project-specific local configuration ($SCOPE_REPO_FILE)" \
        "    user                     " "User-specific configuration ($SCOPE_USER_FILE)" \
        "" "" "$(ansi 97 'Hierarchy')" "" \
        "    Configuration values are resolved in this order of precedence:" \
        "    work > repo > user" \
        "" "" "$(ansi 97 'Examples')" "" \
        "    config --scope=work get work.submodules" \
        "    config -s=user set defaults.shell zsh" \
        "    config --scope work add work.submodules my-service" \
        "    config which organization.name" \
        "    config --scope=work list" \
        "    config --scope work delete \"some.key\"" \
        "$@"
    ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_main config help; exit 1;
        ;;
esac
