#!/bin/bash

# ========================================
# USER INTERACTION HELPERS
# ========================================

# Get user confirmation for yes/no questions
fac_sec_get_user_confirmation() {
    local prompt="$1"
    local default="${2:-N}"
    printf "$(logit --ansi="35" --icon="?" "$prompt \033[35m[Y/N]\033[0m")"
    # Turn off echo and set input to raw mode
    stty -echo -icanon time 0 min 1
    confirm=$(dd bs=1 count=1 2>/dev/null)
    # Restore terminal settings
    stty echo icanon    
    printf "\n"
    case "$confirm" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Get user input with prompt
fac_sec_get_user_input() {
    local prompt="$1"
    local var_name="$2"

    logit --ansi="35" --icon="?" "$prompt: "
    read "$var_name"
}

# Get secret value with hidden input
fac_sec_get_secret_input() {
    local prompt="$1"
    local var_name="$2"

    logit --ansi="35" --icon="?" "$prompt: "
    stty -echo
    read "$var_name"
    stty echo
    printf "\n"
}

# Test encryption key with existing secrets
fac_sec_test_key_with_secrets() {
    local key="$1"
    
    if ! fac_sec_secrets_exist; then
        return 0
    fi
    
    echo "Testing key with existing secrets..."
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(cat "$secret_file")
            local decrypted_value=$(fac_sec_decrypt_data "$encrypted_value" "$key")
            
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                echo "Key validated successfully with secret: $secret_name"
                return 0
            fi
        fi
    done
    
    logit -e "Key validation failed - unable to decrypt existing secrets"
    logit -w "This key cannot decrypt your existing secrets"
    return 1
}

# Re-encrypt all secrets with a new key
fac_sec_reencrypt_all_secrets() {
    local old_key="$1"
    local new_key="$2"
    
    echo "Re-encrypting existing secrets with new key..."
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(cat "$secret_file")
            local decrypted_value=$(fac_sec_decrypt_data "$encrypted_value" "$old_key")
            
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                local new_encrypted=$(fac_sec_encrypt_data "$decrypted_value" "$new_key")
                echo "$new_encrypted" > "$secret_file"
                echo "$secret_name re-encrypted successfully"
            else
                logit -e "Failed to re-encrypt $secret_name"
                return 1
            fi
        fi
    done
    return 0
}
