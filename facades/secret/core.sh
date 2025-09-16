#!/bin/bash

# ========================================
# CORE VALIDATION AND UTILITY FUNCTIONS
# ========================================

sdk_fac_sec_get_secrets_dir() {
    echo "$(cli_ctx config function sdk_fac_con_get_scope_repo_dir)/secrets"
}

# Helper function to check if OpenSSL is available
sdk_fac_sec_check_openssl() {
    if ! command -v _openssl >/dev/null 2>&1; then
        stdout -e "OpenSSL is required but not installed"
        return 1
    fi
    return 0
}

# Check if secrets exist in the secrets directory
sdk_fac_sec_secrets_exist() {
    [ -d "$SECRETS_DIR" ] && [ -n "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]
}

# Validate secret name format
sdk_fac_sec_validate_secret_name() {
    local secret_name="$1"
    
    if [ -z "$secret_name" ]; then
        stdout -e "Secret name cannot be empty"
        return 1
    fi
    
    if ! echo "$secret_name" | grep -q '^[A-Za-z_][A-Za-z0-9_]*$'; then
        stdout -e "Invalid secret name. Use only letters, numbers, and underscores"
        return 1
    fi
    
    return 0
}

# Validate encryption key format
sdk_fac_sec_validate_encryption_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        stdout -e "Encryption key cannot be empty"
        return 1
    fi
    
    if ! echo "$key" | grep -q '^[a-fA-F0-9]\{64\}$'; then
        return 1
    fi
    
    return 0
}
