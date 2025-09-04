#!/bin/bash

# ========================================
# CORE VALIDATION AND UTILITY FUNCTIONS
# ========================================

# Helper function to check if OpenSSL is available
src_fac_sec_check_openssl() {
    if ! command -v _openssl >/dev/null 2>&1; then
        logit -e "OpenSSL is required but not installed"
        return 1
    fi
    return 0
}

# Check if secrets exist in the secrets directory
src_fac_sec_secrets_exist() {
    [ -d "$SECRETS_DIR" ] && [ -n "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]
}

# Validate secret name format
src_fac_sec_validate_secret_name() {
    local secret_name="$1"
    
    if [ -z "$secret_name" ]; then
        logit -e "Secret name cannot be empty"
        return 1
    fi
    
    if ! echo "$secret_name" | grep -q '^[A-Za-z_][A-Za-z0-9_]*$'; then
        logit -e "Invalid secret name. Use only letters, numbers, and underscores"
        return 1
    fi
    
    return 0
}

# Validate encryption key format
src_fac_sec_validate_encryption_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        logit -e "Encryption key cannot be empty"
        return 1
    fi
    
    if ! echo "$key" | grep -q '^[a-fA-F0-9]\{64\}$'; then
        return 1
    fi
    
    return 0
}
