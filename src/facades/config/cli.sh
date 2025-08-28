#!/bin/bash

# config.sh - YAML config file management API
# Usage: source this file and use config_get, config_set, config_delete, config_create
# Uses $CONFIG_FILE environment variable automatically

c=$1; shift; case ""$c"" in
    get) config_get "$@" ;;
    set) config_set "$@" ;;
    del|delete) config_delete "$@" ;;
    array_add) config_array_add "$@" ;;
    array_remove) config_array_remove "$@" ;;
    lis|list) config_keys "$@" ;;
    pri|print) config_print "$@" ;;
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