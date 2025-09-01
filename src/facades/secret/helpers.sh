#!/bin/bash

# Comprehensive secret validation and setup function
# Handles all checks and interactive fixes silently
# Returns 0 if secret is ready to be exported, 1 if failed
fac_sec_validate_and_prepare_secret_interactive() {
    local secret_name="$1"
    
    # Check OpenSSL availability
    if ! fac_sec_check_openssl; then
        return 1
    fi
    
    # Check if secret exists, prompt to add if missing
    if ! fac_sec_secret_exists "$secret_name"; then
        fac_sec_prompt_add_missing_secret "$secret_name"
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    # Validate key configuration and prompt to set if missing
    if ! fac_sec_is_key_configured; then
        logger -e "No encryption key configured" >&2
        if fac_sec_get_user_confirmation "Would you like to set the encryption key now?"; then
            fac_sec_set_key
            if [ $? -ne 0 ]; then
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # Test if we can decrypt the secret with current key
    local key=$(fac_sec_get_encryption_key)
    local encrypted_value=$(fac_sec_read_secret_file "$secret_name")
    local decrypted_value=$(fac_sec_decrypt_data "$encrypted_value" "$key")
    
    if [ $? -ne 0 ] || [ -z "$decrypted_value" ]; then
        # Handle decryption failure interactively
        fac_sec_handle_decryption_failure "$secret_name" "$encrypted_value" >/dev/null
        return $?
    fi
    
    return 0
}

# Prompt to add a missing secret interactively
fac_sec_prompt_add_missing_secret() {
    local secret_name="$1"
    local secret_value

    logger -w "Secret '$secret_name' not found" >&2

    if fac_sec_get_user_confirmation "Would you like to add this secret now?"; then
        fac_sec_get_secret_input "Enter secret value for '$secret_name'" secret_value >&2
        
        if [ -z "$secret_value" ]; then
            logger -e "Secret value cannot be empty" >&2
            return 1
        fi
        
        fac_sec_validate_key_for_operation || return 1
        fac_sec_ensure_encryption_key
        
        local key=$(fac_sec_get_encryption_key)
        fac_sec_encrypt_and_store_secret "$secret_name" "$secret_value" "$key"
        
        logger -o "Secret '$secret_name' added successfully" >&2
        echo "$secret_value"
        return 0
    else
        return 1
    fi
}

# Handle decryption failure with key recovery options
fac_sec_handle_decryption_failure() {
    local secret_name="$1"
    local encrypted_value="$2"
    
    logger -e "Failed to decrypt secret: $secret_name" >&2
    logger -e "The encryption key might be incorrect" >&2
    logger -w "If you've lost the original key, this data cannot be recovered" >&2
    
    echo "Options:" >&2
    echo "1. Try entering the correct key" >&2
    echo "2. Remove this secret and add a new one" >&2
    echo "3. Cancel operation" >&2
    
    fac_sec_get_user_input "Choose option (1-3)" choice >&2
    
    case "$choice" in
        "1")
            if fac_sec_get_user_confirmation "Would you like to re-enter the encryption key?"; then
                fac_sec_set_key
                if [ $? -eq 0 ]; then
                    local new_key=$(fac_sec_get_encryption_key)
                    local decrypted_value=$(fac_sec_decrypt_data "$encrypted_value" "$new_key")
                    if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                        echo "$decrypted_value"
                        return 0
                    else
                        logger -e "Still unable to decrypt - key may be permanently lost" >&2
                        return 1
                    fi
                fi
            fi
            ;;
        "2")
            if fac_sec_get_user_confirmation "Remove '$secret_name' and add a new value?"; then
                rm "$(fac_sec_secret_file_path "$secret_name")" 2>/dev/null
                fac_sec_prompt_add_missing_secret "$secret_name"
                return $?
            fi
            ;;
        *)
            return 1
            ;;
    esac
    
    return 1
}