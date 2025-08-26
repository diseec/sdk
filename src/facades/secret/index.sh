#!/bin/bash

# Secrets manager for secure storage and retrieval of environment variables
# Uses OpenSSL for encryption/decryption with auto-generated key

main() {

    SECRETS_DIR="$ROOT_DIR/secrets"
    mkdir -p "$SECRETS_DIR"

    SRC facades/secret/core.sh
    SRC facades/secret/encryption.sh
    SRC facades/secret/interactions.sh
    SRC facades/secret/key.sh
    SRC facades/secret/secret.sh
    SRC facades/secret/helpers.sh
    SRC facades/secret/cmds.sh

    c=$1; shift; case "$c" in
        kse|key-set) cmd_secret_set_key "$@" ;;
        kre|key-reset) cmd_secret_reset_key "$@" ;;
        ksh|key-show) cmd_secret_show_key "$@" ;;
        add) cmd_secret_add_secret "$@" ;;
        exp|export) cmd_secret_export "$@" ;;
        sho|show) cmd_secret_show_secrets "$@" ;;
        cle|clear) cmd_secret_clear_secrets "$@" ;;
        rem|remove|rm|del|delete) cmd_secret_remove_secret "$@" ;;
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
}