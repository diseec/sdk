#!/bin/bash

# Test encryption key with existing secrets
sdk_fac_sec_test_key_with_secrets() {
    local key="$1"
    
    if ! sdk_fac_sec_secrets_exist; then
        return 0
    fi
    
    stdout -l "Testing key with existing secrets..."
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(cat "$secret_file")
            local decrypted_value=$(sdk_fac_sec_decrypt_data "$encrypted_value" "$key")
            
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                stdout -l "Key validated successfully with secret: $secret_name"
                return 0
            fi
        fi
    done
    
    stdout -e "Key validation failed - unable to decrypt existing secrets"
    stdout -w "This key cannot decrypt your existing secrets"
    return 1
}

# Re-encrypt all secrets with a new key
sdk_fac_sec_reencrypt_all_secrets() {
    local old_key="$1"
    local new_key="$2"
    
    stdout -l "Re-encrypting existing secrets with new key..."
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(cat "$secret_file")
            local decrypted_value=$(sdk_fac_sec_decrypt_data "$encrypted_value" "$old_key")
            
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                local new_encrypted=$(sdk_fac_sec_encrypt_data "$decrypted_value" "$new_key")
                echo "$new_encrypted" > "$secret_file"
                stdout -l "$secret_name re-encrypted successfully"
            else
                stdout -e "Failed to re-encrypt $secret_name"
                return 1
            fi
        fi
    done
    return 0
}
