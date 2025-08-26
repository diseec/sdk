#!/bin/bash

# ========================================
# SECRET MANAGEMENT FUNCTIONS
# ========================================

# Get secret file path for a given secret name
get_secret_file_path() {
    local secret_name="$1"
    echo "$SECRETS_DIR/$secret_name"
}

# Check if a secret exists
secret_exists() {
    local secret_name="$1"
    local secret_file=$(get_secret_file_path "$secret_name")
    [ -f "$secret_file" ]
}

# Read encrypted value from secret file
read_secret_file() {
    local secret_name="$1"
    local secret_file=$(get_secret_file_path "$secret_name")
    
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        return 1
    fi
}

# Write encrypted value to secret file
write_secret_file() {
    local secret_name="$1"
    local encrypted_value="$2"
    local secret_file=$(get_secret_file_path "$secret_name")
    
    echo "$encrypted_value" > "$secret_file"
}

# Decrypt a secret by name
decrypt_secret() {
    local secret_name="$1"
    local key="$2"
    local encrypted_value
    
    encrypted_value=$(read_secret_file "$secret_name") || return 1
    decrypt_data "$encrypted_value" "$key"
}

# Encrypt and store a secret
encrypt_and_store_secret() {
    local secret_name="$1"
    local secret_value="$2"
    local key="$3"
    local encrypted_value
    
    encrypted_value=$(encrypt_data "$secret_value" "$key")
    write_secret_file "$secret_name" "$encrypted_value"
}