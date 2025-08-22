#!/bin/bash

# Secrets manager for secure storage and retrieval of environment variables
# Uses OpenSSL for encryption/decryption with auto-generated key

SECRETS_DIR="$ROOT_DIR/secrets"
mkdir -p "$SECRETS_DIR"

# Helper function to check if OpenSSL is available
check_openssl() {
    if ! command -v _openssl >/dev/null 2>&1; then
        message 31 "ERROR" "OpenSSL is required but not installed"
        return 1
    fi
    return 0
}

# Generate a random encryption key
generate_encryption_key() {
    _openssl rand -hex 32
}

# Helper function to encrypt data
encrypt_data() {
    local data="$1"
    local key="$2"
    printf '%s' "$data" | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" | base64
}

# Helper function to decrypt data
decrypt_data() {
    local encrypted_data="$1"
    local key="$2"
    echo "$encrypted_data" | base64 -d | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -d -pass pass:"$key" 2>/dev/null
}

# Get stored encryption key
get_encryption_key() {
    $CLI config get "secrets_key"
}

# Store encryption key
store_encryption_key() {
    local key="$1"
    $CLI config set "secrets_key" "$key"
    message 32 "SUCCESS" "Encryption key stored in configuration"
}

# Check if encryption key is configured
is_key_configured() {
    local key=$($CLI config get "secrets_key")
    [ -n "$key" ] && [ "$key" != "null" ]
}

# Initialize encryption key if not exists
ensure_encryption_key() {
    if ! is_key_configured; then
        message 34 "INFO" "Generating new encryption key..."
        local new_key=$(generate_encryption_key)
        store_encryption_key "$new_key"
        message 34 "KEY:" "$new_key"
        message 33 "WARNING" "Store this key safely - it's needed to decrypt your secrets!"
        return 0
    fi
    return 0
}

# Check if secrets exist
secrets_exist() {
    [ -d "$SECRETS_DIR" ] && [ -n "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]
}

# Validate key configuration before operations
validate_key_for_operation() {
    if secrets_exist && ! is_key_configured; then
        message 31 "ERROR" "Secrets exist but no encryption key configured!"
        message 33 "WARNING" "You must either:"
        message 34 "INFO" "  1. Provide the original key using: secrets set-key"
        message 34 "INFO" "  2. Remove all existing secrets using: secrets remove <name>"
        message 34 "INFO" "  3. Clear all secrets using: secrets clear"
        return 1
    fi
    return 0
}

# Set encryption key manually
cmd_secret_set_key() {
    check_openssl || return 1
    
    if is_key_configured && ! secrets_exist; then
        message 33 "WARNING" "Encryption key is already configured"
        message 34 "INFO" "Use 'reset-key' to change existing key"
        return 1
    fi
    
    message 45 "?" "Enter encryption key: "
    read encryption_key
    
    if [ -z "$encryption_key" ]; then
        message 31 "ERROR" "Encryption key cannot be empty"
        return 1
    fi
    
    # Validate key format (should be 64 hex characters)
    if ! echo "$encryption_key" | grep -q '^[a-fA-F0-9]\{64\}$'; then
        message 33 "WARNING" "Key should be 64 hexadecimal characters"
        message 45 "?" "Continue anyway? [y/N]: "
        read confirm
        case "$confirm" in
            [yY][eE][sS]|[yY]) ;;
            *) message 34 "INFO" "Operation cancelled"; return 0 ;;
        esac
    fi
    
    # If secrets exist, test the key by trying to decrypt one
    if secrets_exist; then
        message 34 "INFO" "Testing key with existing secrets..."
        local test_successful=false
        for secret_file in "$SECRETS_DIR"/*; do
            if [ -f "$secret_file" ]; then
                local secret_name=$(basename "$secret_file")
                local encrypted_value=$(cat "$secret_file")
                local decrypted_value=$(decrypt_data "$encrypted_value" "$encryption_key")
                
                if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                    message 32 "SUCCESS" "Key validated successfully with secret: $secret_name"
                    test_successful=true
                    break
                fi
            fi
        done
        
        if [ "$test_successful" = false ]; then
            message 31 "ERROR" "Key validation failed - unable to decrypt existing secrets"
            message 33 "WARNING" "This key cannot decrypt your existing secrets"
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
        message 33 "WARNING" "This will re-encrypt all existing secrets with a new key"
        message 33 "WARNING" "Make sure you have the current key before proceeding"
        message 45 "?" "Continue? [y/N]: "
        read confirm
        case "$confirm" in
            [yY][eE][sS]|[yY]) ;;
            *) message 34 "INFO" "Operation cancelled"; return 0 ;;
        esac
        
        # Get current key
        local current_key=$(get_encryption_key)
        
        # Generate new key
        local new_key=$(generate_encryption_key)
        
        # Re-encrypt all existing secrets
        message 34 "INFO" "Re-encrypting existing secrets with new key..."
        for secret_file in "$SECRETS_DIR"/*; do
            if [ -f "$secret_file" ]; then
                local secret_name=$(basename "$secret_file")
                local encrypted_value=$(cat "$secret_file")
                local decrypted_value=$(decrypt_data "$encrypted_value" "$current_key")
                
                if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                    local new_encrypted=$(encrypt_data "$decrypted_value" "$new_key")
                    echo "$new_encrypted" > "$secret_file"
                    message 30 "$secret_name" "Re-encrypted successfully"
                else
                    message 31 "ERROR" "Failed to re-encrypt $secret_name"
                    return 1
                fi
            fi
        done
        
        store_encryption_key "$new_key"
        message 32 "SUCCESS" "All secrets re-encrypted with new key"
        message 33 "IMPORTANT" "New key: $new_key"
        message 33 "WARNING" "Store this key safely!"
    else
        # No secrets exist, just generate new key
        local new_key=$(generate_encryption_key)
        store_encryption_key "$new_key"
        message 32 "SUCCESS" "New encryption key generated"
        message 33 "IMPORTANT" "Key: $new_key"
        message 33 "WARNING" "Store this key safely!"
    fi
}

# Clear all secrets
cmd_secret_clear_secrets() {
    if ! secrets_exist; then
        message 33 "WARNING" "No secrets found"
        return 0
    fi
    
    message 33 "WARNING" "This will permanently delete ALL secrets!"
    message 45 "?" "Are you sure? Type 'DELETE' to confirm: "
    read confirmation
    
    if [ "$confirmation" = "DELETE" ]; then
        rm -f "$SECRETS_DIR"/*
        message 32 "SUCCESS" "All secrets cleared"
    else
        message 34 "INFO" "Operation cancelled"
    fi
}

# Initialize encryption (auto-generate key if not exists)
cmd_secret_init() {
    check_openssl || return 1
    ensure_encryption_key
}

# Show current encryption key
cmd_secret_show_key() {
    if ! is_key_configured; then
        message 31 "ERROR" "No encryption key configured. Run 'secrets init' first"
        return 1
    fi
    
    local key=$(get_encryption_key)
    message 34 "INFO" "Current encryption key:"
    echo "$key"
}

# # Regenerate encryption key (re-encrypt all secrets)
# cmd_regenerate_key() {
#     check_openssl || return 1
    
#     if ! is_key_configured; then
#         message 31 "ERROR" "No encryption key configured. Run 'secrets init' first"
#         return 1
#     fi
    
#     local old_key=$(get_encryption_key)
#     local new_key=$(generate_encryption_key)
    
#     # Re-encrypt all existing secrets with new key
#     if [ -d "$SECRETS_DIR" ] && [ "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
#         message 34 "INFO" "Re-encrypting existing secrets with new key..."
#         for secret_file in "$SECRETS_DIR"/*; do
#             if [ -f "$secret_file" ]; then
#                 local secret_name=$(basename "$secret_file")
#                 local decrypted_value=$(decrypt_data "$(cat "$secret_file")" "$old_key")
#                 if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
#                     local new_encrypted=$(encrypt_data "$decrypted_value" "$new_key")
#                     echo "$new_encrypted" > "$secret_file"
#                     message 30 "$secret_name" "Re-encrypted successfully"
#                 else
#                     message 33 "WARNING" "Failed to re-encrypt $secret_name"
#                 fi
#             fi
#         done
#     fi
    
#     store_encryption_key "$new_key"
#     message 32 "SUCCESS" "New encryption key generated and all secrets re-encrypted"
#     message 33 "IMPORTANT" "New key: $new_key"
#     message 33 "WARNING" "Store this key safely - it's needed to decrypt your secrets!"
# }

# Add a new secret
cmd_secret_add_secret() {
    check_openssl || return 1
    validate_key_for_operation || return 1
    ensure_encryption_key
    
    local key=$(get_encryption_key)
    
    message 45 "?" "Enter secret name (will be used as environment variable): "
    read secret_name
    
    if [ -z "$secret_name" ]; then
        message 31 "ERROR" "Secret name cannot be empty"
        return 1
    fi
    
    # Validate secret name (alphanumeric and underscores only)
    if ! echo "$secret_name" | grep -q '^[A-Za-z_][A-Za-z0-9_]*$'; then
        message 31 "ERROR" "Invalid secret name. Use only letters, numbers, and underscores"
        return 1
    fi
    
    local secret_file="$SECRETS_DIR/$secret_name"
    if [ -f "$secret_file" ]; then
        message 33 "WARNING" "Secret '$secret_name' already exists. Overwrite? [y/N]: "
        read overwrite
        case "$overwrite" in
            [yY][eE][sS]|[yY]) ;;
            *) message 34 "INFO" "Operation cancelled"; return 0 ;;
        esac
    fi
    
    message 45 "?" "Enter secret value: "
    # Turn off echo and read secret value
    stty -echo
    read secret_value
    stty echo
    printf "\n"
    
    if [ -z "$secret_value" ]; then
        message 31 "ERROR" "Secret value cannot be empty"
        return 1
    fi
    
    local encrypted_value=$(encrypt_data "$secret_value" "$key")
    echo "$encrypted_value" > "$secret_file"
    
    message 32 "SUCCESS" "Secret '$secret_name' added successfully"
}

# Get all secrets and export them
cmd_secret_get_all_secrets() {
    check_openssl || return 1
    validate_key_for_operation || return 1
    ensure_encryption_key
    
    if [ ! -d "$SECRETS_DIR" ] || [ -z "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
        message 33 "WARNING" "No secrets found"
        return 0
    fi
    
    local key=$(get_encryption_key)
    message 34 "INFO" "Exporting secrets..."
    
    local export_count=0
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(cat "$secret_file")
            local decrypted_value=$(decrypt_data "$encrypted_value" "$key")
            
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                export "$secret_name"="$decrypted_value"
                echo "export $secret_name=\"$decrypted_value\""
                export_count=$((export_count + 1))
            else
                message 31 "ERROR" "Failed to decrypt secret: $secret_name"
            fi
        fi
    done
    
    if [ $export_count -gt 0 ]; then
        message 32 "SUCCESS" "Exported $export_count secrets"
    else
        message 33 "WARNING" "No secrets were exported"
    fi
}

# List all available secrets (names only)
cmd_secret_list_secrets() {
    if [ ! -d "$SECRETS_DIR" ] || [ -z "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
        message 33 "WARNING" "No secrets found"
        return 0
    fi
    
    message 34 "INFO" "Available secrets:"
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            echo "  $secret_name"
        fi
    done
}

# Show all secrets in a readable format
cmd_secret_show_secrets() {
    check_openssl || return 1
    validate_key_for_operation || return 1
    ensure_encryption_key
    
    if [ ! -d "$SECRETS_DIR" ] || [ -z "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
        message 33 "WARNING" "No secrets found"
        return 0
    fi
    
    local key=$(get_encryption_key)
    message 34 "INFO" "Decrypted secrets:"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│                                   SECRETS                                   │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    
    local secret_count=0
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(cat "$secret_file")
            local decrypted_value=$(decrypt_data "$encrypted_value" "$key")
            
            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                # Format: NAME = VALUE
                printf "│ %-30s = %-44s │\n" "$secret_name" "$decrypted_value"
                secret_count=$((secret_count + 1))
            else
                printf "│ %-30s = %-44s │\n" "$secret_name" "⚠️  FAILED TO DECRYPT"
            fi
        fi
    done
    
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    if [ $secret_count -gt 0 ]; then
        message 32 "SUCCESS" "Displayed $secret_count secrets"
        echo ""
        message 34 "INFO" "Copy commands:"
        for secret_file in "$SECRETS_DIR"/*; do
            if [ -f "$secret_file" ]; then
                local secret_name=$(basename "$secret_file")
                local encrypted_value=$(cat "$secret_file")
                local decrypted_value=$(decrypt_data "$encrypted_value" "$key")
                
                if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                    echo "export $secret_name=\"$decrypted_value\""
                fi
            fi
        done
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
    local secret_file="$SECRETS_DIR/$secret_name"
    
    if [ ! -f "$secret_file" ]; then
        message 31 "ERROR" "Secret '$secret_name' not found"
        return 1
    fi
    
    message 33 "WARNING" "Are you sure you want to remove secret '$secret_name'? [y/N]: "
    read confirm
    case "$confirm" in
        [yY][eE][sS]|[yY])
            rm "$secret_file"
            message 32 "SUCCESS" "Secret '$secret_name' removed"
            ;;
        *)
            message 34 "INFO" "Operation cancelled"
            ;;
    esac
}


# Debug command to test encryption/decryption
cmd_secret_debug() {
    check_openssl || return 1
    validate_key_for_operation || return 1
    ensure_encryption_key
    
    message 34 "DEBUG" "Testing OpenSSL encryption/decryption..."
    test_data="hello world"
    test_key="$(generate_encryption_key)"
    
    message 34 "INFO" "Original: '$test_data'"
    message 34 "INFO" "Test key: '$test_key'"
    
    # Test encryption
    encrypted=$(encrypt_data "$test_data" "$test_key")
    message 34 "INFO" "Encrypted: '$encrypted'"
    
    # Test decryption
    decrypted=$(decrypt_data "$encrypted" "$test_key")
    message 34 "INFO" "Decrypted: '$decrypted'"
    
    if [ "$test_data" = "$decrypted" ]; then
        message 32 "SUCCESS" "Encryption/decryption working correctly"
    else
        message 31 "ERROR" "Encryption/decryption failed"
        message 31 "ERROR" "Expected: '$test_data'"
        message 31 "ERROR" "Got: '$decrypted'"
    fi
    
    # Test if we can debug an actual secret
    if [ ! -d "$SECRETS_DIR" ] || [ -z "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
        message 33 "WARNING" "No actual secrets to debug"
        return 0
    fi
    
    message 34 "DEBUG" "Testing actual secret decryption..."
    local key=$(get_encryption_key)
    
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(cat "$secret_file")
            message 34 "INFO" "Secret: $secret_name"
            message 34 "INFO" "Encrypted data: '$encrypted_value'"
            
            # Try to decrypt with verbose output
            local decrypted_value=$(echo -n "$encrypted_value" | base64 -d | _openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -d -pass pass:"$key" 2>&1)
            local exit_code=$?
            
            message 34 "INFO" "OpenSSL exit code: $exit_code"
            message 34 "INFO" "OpenSSL output: '$decrypted_value'"
            
            if [ $exit_code -eq 0 ] && [ -n "$decrypted_value" ]; then
                message 32 "SUCCESS" "Successfully decrypted: '$decrypted_value'"
            else
                message 31 "ERROR" "Failed to decrypt"
            fi
            break
        fi
    done
}
