#!/bin/bash

# ========================================
# SECRET COMMAND FUNCTIONS
# ========================================

# Add a new secret
cmd_secret_add_secret() {
    check_openssl || return 1
    validate_key_for_operation || return 1
    ensure_encryption_key
    
    local key=$(get_encryption_key)
    local secret_name secret_value
    
    get_user_input "Enter secret name (will be used as environment variable)" secret_name
    validate_secret_name "$secret_name" || return 1
    
    if secret_exists "$secret_name"; then
        message 33 "WARNING" "Secret '$secret_name' already exists."
        if ! get_user_confirmation "Overwrite?"; then
            echo "Operation cancelled"
            return 0
        fi
    fi
    
    get_secret_input "Enter secret value" secret_value
    
    if [ -z "$secret_value" ]; then
        message 31 "ERROR" "Secret value cannot be empty"
        return 1
    fi
    
    encrypt_and_store_secret "$secret_name" "$secret_value" "$key"
    message 32 "SUCCESS" "Secret '$secret_name' added successfully"
}

# Export a single secret by name (returns just the value)
# This function is non-interactive and expects all validations to be done beforehand
cmd_secret_export() {
    if [ -z "$1" ]; then
        message 31 "ERROR" "Secret name required" >&2
        message 34 "INFO" "Usage: secrets export <secret_name>" >&2
        return 1
    fi

    local secret_name="$1"
    
    # Simple checks without interaction
    if ! check_openssl; then
        return 1
    fi
    
    if ! secret_exists "$secret_name"; then
        message 31 "ERROR" "Secret '$secret_name' not found" >&2
        return 1
    fi
    
    if ! is_key_configured; then
        message 31 "ERROR" "No encryption key configured" >&2
        return 1
    fi
    
    # Attempt to decrypt and return the value
    local key=$(get_encryption_key)
    local encrypted_value=$(read_secret_file "$secret_name")
    local decrypted_value=$(decrypt_data "$encrypted_value" "$key")
    
    if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
        echo "$decrypted_value"
        return 0
    else
        message 31 "ERROR" "Failed to decrypt secret '$secret_name'" >&2
        return 1
    fi
}

# Show all secrets in a readable format
cmd_secret_show_secrets() {
    check_openssl || return 1
    validate_key_for_operation || return 1
    ensure_encryption_key
    
    if ! secrets_exist; then
        message 33 "WARNING" "No secrets found"
        return 0
    fi
    
    local key=$(get_encryption_key)
    local secret_count=0
    
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local decrypted_value=$(decrypt_secret "$secret_name" "$key")
            
            echo ""
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                message 34 "$secret_name" "$decrypted_value"
                secret_count=$((secret_count + 1))
            else
                message 34 "$secret_name" "⚠️ FAILED TO DECRYPT"
            fi
        fi
    done
    
    echo ""
    
    if [ $secret_count -gt 0 ]; then
        echo "Total: $secret_count secrets"
        echo "To export a secret as environment variables:"
        echo "export SECRET_NAME=\"\$(\$CLI secret export 'SECRET_NAME')\""
    else
        message 33 "WARNING" "No secrets were displayed"
    fi
}

# Remove a secret
cmd_secret_remove_secret() {
    if [ -z "$1" ]; then
        message 31 "ERROR" "Secret name required"
        message 34 "INFO" "Usage: secrets remove <secret_name>"
        return 1
    fi
    
    local secret_name="$1"
    
    if ! secret_exists "$secret_name"; then
        message 31 "ERROR" "Secret '$secret_name' not found"
        return 1
    fi
    
    if get_user_confirmation "Are you sure you want to remove secret '$secret_name'?"; then
        local secret_file=$(get_secret_file_path "$secret_name")
        rm "$secret_file"
        message 32 "SUCCESS" "Secret '$secret_name' removed"
    else
        message 34 "INFO" "Operation cancelled"
    fi
}
