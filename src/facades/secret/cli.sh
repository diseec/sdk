#!/bin/bash

c=$1; shift; case "$c" in
    kse|key-set) fac_sec_set_key "$@" ;;
    kre|key-reset) fac_sec_reset_key "$@" ;;
    ksh|key-show) fac_sec_show_key "$@" ;;
    add) fac_sec_add_secret "$@" ;;
    exp|export) fac_sec_export "$@" ;;
    sho|show) fac_sec_show_secrets "$@" ;;
    cle|clear) fac_sec_clear_secrets "$@" ;;
    rem|remove|rm|del|delete) fac_sec_remove_secret "$@" ;;
    *) display_help "" "" \
        "$(color 30 'Secrets Commands')" "" \
        "    kse|key-set            " "Set encryption key manually" \
        "    kre|key-reset          " "Generate new key and re-encrypt all secrets" \
        "    ksh|key-show           " "Display current encryption key" \
        "    add                    " "Add a new secret interactively" \
        "    sho|show               " "Display all secrets in readable format" \
        "    exp|export             " "Export a secret value" \
        "    cle|clear              " "Remove all secrets (requires confirmation)" \
        "    rem|remove <name>      " "Remove a specific secret" \
        "" "" "$(color 34 'Info: ')" "Secrets are encrypted with AES-256-CBC using auto-generated keys" \
        "" "" "$(color 30 'Important: ')" "If secrets exist but no key is configured, you ust:" \
        "    1. Set the original key manually: secrets set-key" "" \
        "    2. Clear all secrets: secrets clear" ""
    ;;
esac