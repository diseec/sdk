#!/bin/bash

# ========================================
# KEY MANAGEMENT COMMANDS
# ========================================

# Set encryption key manually
fac_sec_set_key() {
    fac_sec_check_openssl || return 1
    
    if fac_sec_is_key_configured && ! fac_sec_secrets_exist; then
        message 33 "!" "Encryption key is already configured"
        message 34 "i" "Use 'reset-key' to change existing key"
        return 1
    fi
    
    local encryption_key
    fac_sec_get_user_input "Enter encryption key" encryption_key
    
    if [ -z "$encryption_key" ]; then
        message 31 "E" "Encryption key cannot be empty"
        return 1
    fi
    
    # Validate key format
    if ! fac_sec_validate_encryption_key "$encryption_key"; then
        message 33 "!" "Key should be 64 hexadecimal characters"
        if ! fac_sec_get_user_confirmation "Continue anyway?"; then
            return 0
        fi
    fi
    
    # Test key with existing secrets
    if fac_sec_secrets_exist; then
        if ! fac_sec_test_key_with_secrets "$encryption_key"; then
            return 1
        fi
    fi
    
    fac_sec_store_encryption_key "$encryption_key"
    message 32 "✔" "Encryption key configured successfully"
}

# Reset encryption key
fac_sec_reset_key() {
    fac_sec_check_openssl || return 1
    
    if ! fac_sec_is_key_configured; then
        message 31 "E" "No encryption key configured. Use 'set-key' first"
        return 1
    fi
    
    if fac_sec_secrets_exist; then
        message 33 "!" "This will re-encrypt all existing secrets with a new key"
        message 33 "!" "Make sure you have the current key before proceeding"
        
        if ! fac_sec_get_user_confirmation "Continue?"; then
            return 0
        fi
        
        local current_key=$(fac_sec_get_encryption_key)
        local new_key=$(fac_sec_generate_encryption_key)
        
        if fac_sec_reencrypt_all_secrets "$current_key" "$new_key"; then
            fac_sec_store_encryption_key "$new_key"
            echo "All secrets re-encrypted with new key"
            echo "New key: $new_key"
            message 33 "!" "Store this key safely!"
        else
            return 1
        fi
    else
        local new_key=$(fac_sec_generate_encryption_key)
        fac_sec_store_encryption_key "$new_key"
        echo "New encryption key generated"
        echo "Key: $new_key"
        message 33 "!" "Store this key safely!"
    fi
}

# Show current encryption key
fac_sec_show_key() {
    if ! fac_sec_is_key_configured; then
        message 31 "E" "No encryption key configured. Run 'secrets init' first"
        return 1
    fi
    
    local key=$(fac_sec_get_encryption_key)
    echo "Current encryption key:"
    echo "$key"
}

# Clear all secrets
fac_sec_clear_secrets() {
    if ! fac_sec_secrets_exist; then
        message 33 "!" "No secrets found"
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
