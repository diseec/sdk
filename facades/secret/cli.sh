#!/bin/bash

source_once "$D_SDK_DIR/facades/secret/index.sh"

mkdir -p "$SECRETS_DIR"

c=$1; shift; case "$c" in
    ini|init) sdk_fac_sec_cmd_init_secret "$@" ;; # no need for manual call automatically called on first add/validate
    kse|key-set) sdk_fac_sec_set_key "$@" ;;
    kre|key-reset) sdk_fac_sec_reset_key "$@" ;;
    ksh|key-show) sdk_fac_sec_show_key "$@" ;;
    add) sdk_fac_sec_add_secret "$@" ;;
    exp|export) sdk_fac_sec_export "$@" ;;
    pri|print) sdk_fac_sec_show_secrets "$@" ;;
    cle|clear) sdk_fac_sec_clear_secrets "$@" ;;
    rem|remove|rm|del|delete) sdk_fac_sec_remove_secret "$@" ;;
    ava|available) sdk_fac_sec_cmd_check_availability "$@" ;;
    val|validate) sdk_fac_sec_cmd_validate_secret "$@" ;;
    exi|exists) sdk_fac_sec_cmd_secret_exists "$@" ;;
    fun|function) "$@" ;;
    *) display_help "" "" \
        "$(ansi 97 'Secrets Commands')" "" \
        "$(ansi 97 'Usage:    cli secret <command> [options]')" "" "" "" \
        "$(ansi "1;90" "$(capitalize 'Core Commands')")" "" \
        "    add                    " "Add a new secret interactively" \
        "    exp|export <name>      " "Export a secret value (non-interactive)" \
        "    pri|print              " "Display all secrets in readable format" \
        "    rem|remove <name>      " "Remove a specific secret" \
        "    cle|clear              " "Remove all secrets (requires confirmation)" \
        "" "" "$(ansi "1;90" "$(capitalize 'Key Management')")" "" \
        "    kse|key-set            " "Set encryption key manually" \
        "    kre|key-reset          " "Generate new key and re-encrypt all secrets" \
        "    ksh|key-show           " "Display current encryption key" \
        "" "" "$(ansi "1;90" "$(capitalize 'Validation & Status')")" "" \
        "    ava|available          " "Check if secrets system is available" \
        "    val|validate <name>    " "Validate and prepare a secret (interactive)" \
        "    ini|init <name>        " "Initialize and ensure a secret exists (interactive)" \
        "                           " "$(ansi "2;90" "No need for manual call,")" \
        "                           " "$(ansi "2;90" "init happens automatically")" \
        "    exi|exists <name>      " "Check if a secret exists" \
        "" "" "$(ansi 34 'Info: ')" "Secrets are encrypted with AES-256-CBC using auto-generated keys" \
        "" "" "$(ansi 97 'Important: ')" "If secrets exist but no key is configured, you must:" \
        "    1. Set the original key manually: secret key-set" "" \
        "    2. Clear all secrets: secret clear" ""
    ;;
esac