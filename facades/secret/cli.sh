#!/bin/bash

source_once "$D_SDK_DIR/facades/secret/index.sh"

mkdir -p "$SECRETS_DIR"

c=$1; shift; case "$c" in
    kse|key-set) src_fac_sec_set_key "$@" ;;
    kre|key-reset) src_fac_sec_reset_key "$@" ;;
    ksh|key-show) src_fac_sec_show_key "$@" ;;
    add) src_fac_sec_add_secret "$@" ;;
    exp|export) src_fac_sec_export "$@" ;;
    pri|print) src_fac_sec_show_secrets "$@" ;;
    cle|clear) src_fac_sec_clear_secrets "$@" ;;
    rem|remove|rm|del|delete) src_fac_sec_remove_secret "$@" ;;
    fun|function) "$@" ;;
    *) display_help "" "" \
        "$(ansi 97 'Secrets Commands')" "" \
        "    kse|key-set            " "Set encryption key manually" \
        "    kre|key-reset          " "Generate new key and re-encrypt all secrets" \
        "    ksh|key-show           " "Display current encryption key" \
        "    add                    " "Add a new secret interactively" \
        "    pri|print              " "Display all secrets in readable format" \
        "    exp|export             " "Export a secret value" \
        "    cle|clear              " "Remove all secrets (requires confirmation)" \
        "    rem|remove <name>      " "Remove a specific secret" \
        "" "" "$(ansi 34 'Info: ')" "Secrets are encrypted with AES-256-CBC using auto-generated keys" \
        "" "" "$(ansi 97 'Important: ')" "If secrets exist but no key is configured, you ust:" \
        "    1. Set the original key manually: secrets set-key" "" \
        "    2. Clear all secrets: secrets clear" ""
    ;;
esac