#!/bin/bash

# ========================================
# CORE VALIDATION AND UTILITY FUNCTIONS
# ========================================

# Helper function to check if OpenSSL is available
fac_sec_check_openssl() {
    if ! command -v _openssl >/dev/null 2>&1; then
        message 41 "!" "OpenSSL is required but not installed"
        return 1
    fi
    return 0
}

# Check if secrets exist in the secrets directory
fac_sec_secrets_exist() {
    [ -d "$SECRETS_DIR" ] && [ -n "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]
}

# Validate secret name format
fac_sec_validate_secret_name() {
    local secret_name="$1"
    
    if [ -z "$secret_name" ]; then
        message 41 "!" "Secret name cannot be empty"
        return 1
    fi
    
    if ! echo "$secret_name" | grep -q '^[A-Za-z_][A-Za-z0-9_]*$'; then
        message 41 "!" "Invalid secret name. Use only letters, numbers, and underscores"
        return 1
    fi
    
    return 0
}

# Validate encryption key format
fac_sec_validate_encryption_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        message 41 "!" "Encryption key cannot be empty"
        return 1
    fi
    
    if ! echo "$key" | grep -q '^[a-fA-F0-9]\{64\}$'; then
        return 1
    fi
    
    return 0
}
