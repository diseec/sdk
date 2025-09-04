#!/bin/bash

# ========================================
# SECRET MANAGEMENT FUNCTIONS
# ========================================

# Get secret file path for a given secret name
src_fac_sec_secret_file_path() {
    local secret_name="$1"
    echo "$SECRETS_DIR/$secret_name"
}

# Check if a secret exists
src_fac_sec_secret_exists() {
    local secret_name="$1"
    local secret_file=$(src_fac_sec_secret_file_path "$secret_name")
    [ -f "$secret_file" ]
}

# Read encrypted value from secret file
src_fac_sec_read_secret_file() {
    local secret_name="$1"
    local secret_file=$(src_fac_sec_secret_file_path "$secret_name")
    
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        return 1
    fi
}

# Write encrypted value to secret file
src_fac_sec_write_secret_file() {
    local secret_name="$1"
    local encrypted_value="$2"
    local secret_file=$(src_fac_sec_secret_file_path "$secret_name")
    
    echo "$encrypted_value" > "$secret_file"
}

# Decrypt a secret by name
src_fac_sec_decrypt_secret() {
    local secret_name="$1"
    local key="$2"
    local encrypted_value
    
    encrypted_value=$(src_fac_sec_read_secret_file "$secret_name") || return 1
    src_fac_sec_decrypt_data "$encrypted_value" "$key"
}

# Encrypt and store a secret
src_fac_sec_encrypt_and_store_secret() {
    local secret_name="$1"
    local secret_value="$2"
    local key="$3"
    local encrypted_value
    
    encrypted_value=$(src_fac_sec_encrypt_data "$secret_value" "$key")
    src_fac_sec_write_secret_file "$secret_name" "$encrypted_value"
}