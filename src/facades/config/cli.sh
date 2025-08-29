#!/bin/bash

# config.sh - YAML config file management API
# Usage: source this file and use fac_con_config_get, fac_con_config_set, fac_con_config_delete, config_create
# Uses $CONFIG_FILE environment variable automatically

c=$1; shift; case ""$c"" in
    get) fac_con_config_get "$@" ;;
    set) fac_con_config_set "$@" ;;
    del|delete) fac_con_config_delete "$@" ;;
    array_add) fac_con_config_array_add "$@" ;;
    array_remove) fac_con_config_array_remove "$@" ;;
    lis|list) fac_con_config_keys "$@" ;;
    pri|print) fac_con_config_print "$@" ;;
    *) display_help "" "" \
        "$(color 30 'Config Commands')" "" \
        "    get <key.path>                   " "Get value from configuration" \
        "    set <key.path> <value>           " "Set value in configuration" \
        "    del|delete <key.path>            " "Delete key from configuration" \
        "    array_add <key.path> <val>       " "Add item to array" \
        "    array_remove <key.path> <val>    " "Remove item from array" \
        "    lis|list                         " "List all configuration keys" \
        "    pri|print                        " "Print entire configuration"
    ;;
esac 