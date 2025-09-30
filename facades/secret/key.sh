#!/bin/bash

# ========================================
# KEY MANAGEMENT COMMANDS
# ========================================

# Set encryption key manually
sdk_fac_sec_set_key() {
    sdk_fac_sec_check_openssl || return 1
    
    if sdk_fac_sec_is_key_configured && ! sdk_fac_sec_secrets_exist; then
        stdout -w "Encryption key is already configured"
        stdout -i "Use 'reset-key' to change existing key"
        return 1
    fi
    
    local encryption_key
    stdin encryption_key "Enter encryption key" --hidden
    
    if [ -z "$encryption_key" ]; then
        stdout -e "Encryption key cannot be empty"
        return 1
    fi
    
    # Validate key format
    if ! sdk_fac_sec_validate_encryption_key "$encryption_key"; then
        stdout -w "Key should be 64 hexadecimal characters"
        if ! confirm "Continue anyway?"; then
            return 0
        fi
    fi
    
    # Test key with existing secrets
    if sdk_fac_sec_secrets_exist; then
        if ! sdk_fac_sec_test_key_with_secrets "$encryption_key"; then
            return 1
        fi
    fi
    
    sdk_fac_sec_store_encryption_key "$encryption_key"
    stdout -o "Encryption key configured successfully"
}

# Reset encryption key
sdk_fac_sec_reset_key() {
    sdk_fac_sec_check_openssl || return 1
    
    if ! sdk_fac_sec_is_key_configured; then
        stdout -e "No encryption key configured. Use 'set-key' first"
        return 1
    fi
    
    if sdk_fac_sec_secrets_exist; then
        stdout -w "This will re-encrypt all existing secrets with a new key"
        stdout -w "Make sure you have the current key before proceeding"
        
        if ! confirm "Continue?"; then
            return 0
        fi
        
        local current_key=$(sdk_fac_sec_get_encryption_key)
        local new_key=$(sdk_fac_sec_generate_encryption_key)
        
        if sdk_fac_sec_reencrypt_all_secrets "$current_key" "$new_key"; then
            sdk_fac_sec_store_encryption_key "$new_key"
            stdout -l "All secrets re-encrypted with new key"
            stdout -l "New key: $new_key"
            stdout -w "Store this key safely!"
        else
            return 1
        fi
    else
        local new_key=$(sdk_fac_sec_generate_encryption_key)
        sdk_fac_sec_store_encryption_key "$new_key"
        stdout -l "New encryption key generated"
        stdout -i "Key: $new_key"
        stdout -w "Store this key safely!"
    fi
}

# Show current encryption key
sdk_fac_sec_show_key() {
    if ! sdk_fac_sec_is_key_configured; then
        stdout -e "No encryption key configured. Run 'secrets init' first"
        return 1
    fi
    
    local key=$(sdk_fac_sec_get_encryption_key)
    stdout -l "Current encryption key:"
    echo "$key"
}

# Clear all secrets
sdk_fac_sec_clear_secrets() {
    # Ensure the secrets directory exists
    mkdir -p "$SECRETS_DIR"
    fix_permissions "$SECRETS_DIR"
    
    # Check if secrets directory has any files
    if [ ! -n "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
        stdout -w "No secrets found"
        return 0
    fi

    stdout -w "This will permanently delete ALL secrets!"
    stdin confirmation "Are you sure? Type 'DELETE' to confirm:"

    if [ "$confirmation" = "DELETE" ]; then
        # Remove all files but keep the directory
        rm -f "$SECRETS_DIR"/*
        stdout -l "All secrets cleared"
        return 0
    else
        stdout -l "Operation cancelled"
        # Explicitly exit with non-zero to ensure it's propagated properly
        return 1
    fi
}
