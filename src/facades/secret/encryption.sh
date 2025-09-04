#!/bin/bash

# ========================================
# ENCRYPTION AND KEY MANAGEMENT
# ========================================

# Generate a random encryption key
src_fac_sec_generate_encryption_key() {
    _openssl rand -hex 32
}

# Helper function to encrypt data
src_fac_sec_encrypt_data() {
    local data="$1"
    local key="$2"
    printf '%s' "$data" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64
}

# Helper function to decrypt data
src_fac_sec_decrypt_data() {
    local encrypted_data="$1"
    local key="$2"
    echo "$encrypted_data" | base64 -d | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -d -pass pass:"$key" 2>/dev/null
}

# Get stored encryption key
src_fac_sec_get_encryption_key() {
    cli_main config get "secrets.key"
}

# Store encryption key
src_fac_sec_store_encryption_key() {
    local key="$1"
    cli_main config set "secrets.key" "$key"
    echo "Encryption key stored in configuration"
}

# Check if encryption key is configured
src_fac_sec_is_key_configured() {
    local key=$(cli_main config get "secrets.key")
    [ -n "$key" ] && [ "$key" != "null" ]
}

# Initialize encryption key if not exists
src_fac_sec_ensure_encryption_key() {
    if ! src_fac_sec_is_key_configured; then
        echo "Generating new encryption key..."
        local new_key=$(src_fac_sec_generate_encryption_key)
        src_fac_sec_store_encryption_key "$new_key"
        logit --ansi="34" --icon="KEY" "$new_key"
        logit -w "Store this key safely - it's needed to decrypt your secrets!"
        return 0
    fi
    return 0
}

# Validate key configuration before operations
src_fac_sec_validate_key_for_operation() {
    if src_fac_sec_secrets_exist && ! src_fac_sec_is_key_configured; then
        logit -e "Secrets exist but no encryption key configured!"
        echo "You must either:"
        echo "  1. Provide the original key using: secrets key-set"
        echo "  2. Remove all existing secrets using: secrets remove <name>"
        echo "  3. Clear all secrets using: secrets clear"
        return 1
    fi
    return 0
}