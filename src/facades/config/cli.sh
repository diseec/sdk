#!/bin/bash

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
    get) fac_con_get "$@" "$SCOPE" ;;
    set) fac_con_set "$@" "$SCOPE" ;;
    add) fac_con_array_add "$@" "$SCOPE" ;;
    rem|remove) fac_con_array_remove "$@" "$SCOPE" ;;
    del|delete) fac_con_delete "$@" "$SCOPE" ;;
    pat|path) fac_con_get_config_file "$SCOPE" ;;
    whi|which) fac_con_which "$@" ;;
    pri|print) 
        # Print can work without scope (prints all scopes) or with scope
        if [ -n "$SCOPE" ]; then fac_con_print "$@" "$SCOPE"
        else fac_con_print "$@"; fi
    ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi 97 'Configuration Management System')" "" \
        "" "" "$(ansi 97 'Usage:    config [SCOPE_OPTIONS] <command> [arguments]')" "" \
        "$(ansi 97 'Scope Options (mandatory for most commands)')" "" \
        "    -s=<scope>               " "Set scope (short form)" \
        "    --scope=<scope>          " "Set scope (long form with equals)" \
        "    --scope <scope>          " "Set scope (long form with space)" \
        "" "" "$(ansi 97 'Commands')" "" \
        "    get <key.path>           " "Get configuration value with hierarchy resolution" \
        "    set <key.path> <value>   " "Set configuration value in specified scope" \
        "    add <key.path> <value>   " "Add value to configuration array" \
        "    rem|remove <key.path> <val>" "Remove value from configuration array" \
        "    del|delete <key.path>    " "Delete configuration key from specified scope" \
        "    whi|which <key.path>     " "Show configuration value resolution path (no scope needed)" \
        "    pat|path                 " "Show configuration path (no scope needed)" \
        "    pri|print                " "Print configuration for scope (or all if no scope)" \
        "    hel|help                 " "Show this help message" \
        "" "" "$(ansi 97 'Scopes')" "" \
        "    project                  " "Project-specific configuration (.kit/project.yaml)" \
        "    workspace                " "Workspace-specific configuration (workspaces/\$REPO_NAME/workspace.yaml)" \
        "    user                     " "User-specific configuration (users/\$USER/user.yaml)" \
        "    global                   " "Organization-wide configuration (config.yaml)" \
        "" "" "$(ansi 97 'Hierarchy')" "" \
        "    Configuration values are resolved in this order of precedence:" \
        "    project > workspace > user > global" \
        "" "" "$(ansi 97 'Examples')" "" \
        "    config --scope=workspace get workspace.submodules" \
        "    config -s=global set defaults.shell zsh" \
        "    config --scope workspace add workspace.submodules my-service" \
        "    config which organization.name" \
        "    config --scope=workspace list" \
        "    config --scope workspace delete \"some.key\"" \
        "$@"
    ;;
    *)
        logit -e "Unknown command: '$c'"
        cli_main config help; exit 1;
        ;;
esac
