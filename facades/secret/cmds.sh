#!/bin/bash

# ========================================
# SECRET COMMAND FUNCTIONS
# ========================================

# Add a new secret
sdk_fac_sec_add_secret() {
    sdk_fac_sec_check_openssl || return 1
    sdk_fac_sec_validate_key_for_operation || return 1
    sdk_fac_sec_ensure_encryption_key
    
    local key=$(sdk_fac_sec_get_encryption_key)
    local secret_name secret_value
    
    sdk_fac_sec_get_user_input "Enter secret name (will be used as environment variable)" secret_name
    sdk_fac_sec_validate_secret_name "$secret_name" || return 1
    
    if sdk_fac_sec_secret_exists "$secret_name"; then
        logit -w "Secret '$secret_name' already exists."
        if ! sdk_fac_sec_get_user_confirmation "Overwrite?"; then
            logit -o "Secret '$secret_name' unchanged"
            return 0
        fi
    fi
    
    sdk_fac_sec_get_secret_input "Enter secret value" secret_value
    
    if [ -z "$secret_value" ]; then
        logit -e "Secret value cannot be empty"
        return 1
    fi
    
    sdk_fac_sec_encrypt_and_store_secret "$secret_name" "$secret_value" "$key"
    logit -o "Secret '$secret_name' added successfully"
}

# Export a single secret by name (returns just the value)
# This function is non-interactive and expects all validations to be done beforehand
sdk_fac_sec_export() {
    if [ -z "$1" ]; then
        logit -e "Secret name required" >&2
        logit -i "Usage: secrets export <secret_name>" >&2
        return 1
    fi

    local secret_name="$1"
    
    # Simple checks without interaction
    if ! sdk_fac_sec_check_openssl; then
        return 1
    fi
    
    if ! sdk_fac_sec_secret_exists "$secret_name"; then
        logit -e "Secret '$secret_name' not found" >&2
        return 1
    fi
    
    if ! sdk_fac_sec_is_key_configured; then
        logit -e "No encryption key configured" >&2
        if sdk_fac_sec_get_user_confirmation "Would you like to set the encryption key now?"; then
            sdk_fac_sec_set_key
            if [ $? -ne 0 ]; then
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # Attempt to decrypt and return the value
    local key=$(sdk_fac_sec_get_encryption_key)
    local encrypted_value=$(sdk_fac_sec_read_secret_file "$secret_name")
    local decrypted_value=$(sdk_fac_sec_decrypt_data "$encrypted_value" "$key")
    
    if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
        echo "$decrypted_value"
        return 0
    else
        logit -e "Failed to decrypt secret '$secret_name'" >&2
        return 1
    fi
}

# Show all secrets in a readable format
sdk_fac_sec_show_secrets() {
    sdk_fac_sec_check_openssl || return 1
    sdk_fac_sec_validate_key_for_operation || return 1
    sdk_fac_sec_ensure_encryption_key
    
    if ! sdk_fac_sec_secrets_exist; then
        logit -w "No secrets found"
        return 0
    fi
    
    local key=$(sdk_fac_sec_get_encryption_key)
    local secret_count=0
    
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local decrypted_value=$(sdk_fac_sec_decrypt_secret "$secret_name" "$key")
            
            echo ""
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                logit --ansi="34" --icon="$secret_name" "$decrypted_value"
                secret_count=$((secret_count + 1))
            else
                logit --ansi="34" --icon="$secret_name" "⚠️ FAILED TO DECRYPT"
            fi
        fi
    done
    
    echo ""
    
    if [ $secret_count -gt 0 ]; then
        echo "Total: $secret_count secrets"
        echo "To export a secret as environment variables:"
        echo "export SECRET_NAME=\"\$(\$D_CLI_STUB secret export 'SECRET_NAME')\""
    else
        logit -w "No secrets were displayed"
    fi
}

# Remove a secret
sdk_fac_sec_remove_secret() {
    if [ -z "$1" ]; then
        logit -e "Secret name required"
        logit -i "Usage: secrets remove <secret_name>"
        return 1
    fi
    
    local secret_name="$1"
    
    if ! sdk_fac_sec_secret_exists "$secret_name"; then
        logit -e "Secret '$secret_name' not found"
        return 1
    fi
    
    if sdk_fac_sec_get_user_confirmation "Are you sure you want to remove secret '$secret_name'?"; then
        local secret_file=$(sdk_fac_sec_secret_file_path "$secret_name")
        rm "$secret_file"
        logit -o "Secret '$secret_name' removed"
    else
        logit -i "Operation cancelled"
    fi
}
