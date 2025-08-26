#!/bin/bash

# ========================================
# ENCRYPTION AND KEY MANAGEMENT
# ========================================

# Generate a random encryption key
generate_encryption_key() {
    _openssl rand -hex 32
}

# Helper function to encrypt data
encrypt_data() {
    local data="$1"
    local key="$2"
    printf '%s' "$data" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64
}

# Helper function to decrypt data
decrypt_data() {
    local encrypted_data="$1"
    local key="$2"
    echo "$encrypted_data" | base64 -d | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -d -pass pass:"$key" 2>/dev/null
}

# Get stored encryption key
get_encryption_key() {
    $CLI workspace config get "secrets.key"
}

# Store encryption key
store_encryption_key() {
    local key="$1"
    $CLI workspace config set "secrets.key" "$key"
    echo "Encryption key stored in configuration"
}

# Check if encryption key is configured
is_key_configured() {
    local key=$($CLI workspace config get "secrets.key")
    [ -n "$key" ] && [ "$key" != "null" ]
}

# Initialize encryption key if not exists
ensure_encryption_key() {
    if ! is_key_configured; then
        echo "Generating new encryption key..."
        local new_key=$(generate_encryption_key)
        store_encryption_key "$new_key"
        message 34 "KEY:" "$new_key"
        message 33 "WARNING" "Store this key safely - it's needed to decrypt your secrets!"
        return 0
    fi
    return 0
}

# Validate key configuration before operations
validate_key_for_operation() {
    if secrets_exist && ! is_key_configured; then
        message 31 "ERROR" "Secrets exist but no encryption key configured!"
        echo "You must either:"
        echo "  1. Provide the original key using: secrets set-key"
        echo "  2. Remove all existing secrets using: secrets remove <name>"
        echo "  3. Clear all secrets using: secrets clear"
        return 1
    fi
    return 0
}