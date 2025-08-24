#!/bin/bash

# ========================================
# KEY MANAGEMENT COMMANDS
# ========================================

# Set encryption key manually
cmd_secret_set_key() {
    check_openssl || return 1
    
    if is_key_configured && ! secrets_exist; then
        message 33 "WARNING" "Encryption key is already configured"
        message 34 "INFO" "Use 'reset-key' to change existing key"
        return 1
    fi
    
    local encryption_key
    get_user_input "Enter encryption key" encryption_key
    
    if [ -z "$encryption_key" ]; then
        message 31 "ERROR" "Encryption key cannot be empty"
        return 1
    fi
    
    # Validate key format
    if ! validate_encryption_key "$encryption_key"; then
        message 33 "WARNING" "Key should be 64 hexadecimal characters"
        if ! get_user_confirmation "Continue anyway?"; then
            message 34 "INFO" "Operation cancelled"
            return 0
        fi
    fi
    
    # Test key with existing secrets
    if secrets_exist; then
        if ! test_key_with_secrets "$encryption_key"; then
            return 1
        fi
    fi
    
    store_encryption_key "$encryption_key"
    message 32 "SUCCESS" "Encryption key configured successfully"
}

# Reset encryption key
cmd_secret_reset_key() {
    check_openssl || return 1
    
    if ! is_key_configured; then
        message 31 "ERROR" "No encryption key configured. Use 'set-key' first"
        return 1
    fi
    
    if secrets_exist; then
        message 43 "!" "This will re-encrypt all existing secrets with a new key"
        message 43 "!" "Make sure you have the current key before proceeding"
        
        if ! get_user_confirmation "Continue?"; then
            echo "Operation cancelled"
            return 0
        fi
        
        local current_key=$(get_encryption_key)
        local new_key=$(generate_encryption_key)
        
        if reencrypt_all_secrets "$current_key" "$new_key"; then
            store_encryption_key "$new_key"
            echo "All secrets re-encrypted with new key"
            echo "New key: $new_key"
            message 33 "WARNING" "Store this key safely!"
        else
            return 1
        fi
    else
        local new_key=$(generate_encryption_key)
        store_encryption_key "$new_key"
        echo "New encryption key generated"
        echo "Key: $new_key"
        message 33 "WARNING" "Store this key safely!"
    fi
}

# Show current encryption key
cmd_secret_show_key() {
    if ! is_key_configured; then
        message 31 "ERROR" "No encryption key configured. Run 'secrets init' first"
        return 1
    fi
    
    local key=$(get_encryption_key)
    echo "Current encryption key:"
    echo "$key"
}

# Clear all secrets
cmd_secret_clear_secrets() {
    if ! secrets_exist; then
        message 33 "WARNING" "No secrets found"
        return 0
    fi
    
    message 43 "WARNING" "This will permanently delete ALL secrets!"
    message 45 "?" "Are you sure? Type 'DELETE' to confirm: "
    read confirmation
    
    if [ "$confirmation" = "DELETE" ]; then
        rm -f "$SECRETS_DIR"/*
        echo "All secrets cleared"
    else
        echo "Operation cancelled"
    fi
}
