#!/bin/bash
# Secret Module - Command Implementations
# CLI command implementations for secret management


# ========================================
# SECRET COMMAND FUNCTIONS
# ========================================

# Add a new secret
sdk_fac_sec_add_secret() {    
    sdk_fac_sec_check_openssl || return 1
    sdk_fac_sec_ensure_encryption_key || return 1

    local key=$(sdk_fac_sec_get_encryption_key)
    if [ -z "$key" ]; then
        stdout -e "Failed to retrieve encryption key"
        return 1
    fi

    local secret_name secret_value file_path=""

    # Parse arguments for flags
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--file)
                if [ -z "$2" ]; then
                    stdout -e "Flag $1 requires a file path"
                    return 1
                fi
                file_path="$2"
                shift 2
                ;;
            -*)
                stdout -e "Unknown flag: $1"
                stdout -i "Usage: D secret add [secret_name] [secret_value] [-f|--file <file_path>]"
                return 1
                ;;
            *)
                if [ -z "$secret_name" ]; then
                    secret_name="$1"
                    shift
                elif [ -z "$file_path" ]; then
                    # Only collect remaining args as secret_value if no file flag
                    secret_value="$*"
                    break
                else
                    shift
                fi
                ;;
        esac
    done

    # Get secret name if not provided
    if [ -z "$secret_name" ]; then
        stdin secret_name "Enter secret name (will be used as environment variable)" --required
    fi

    sdk_fac_sec_validate_secret_name "$secret_name" || return 1
    
    if sdk_fac_sec_secret_exists "$secret_name"; then
        stdout -w "Secret '$secret_name' already exists."
        if ! confirm "Overwrite?"; then
            stdout -o "Secret '$secret_name' unchanged"
            return 0
        fi
    fi
    
    # Get secret value from file or input
    if [ -n "$file_path" ]; then
        if [ ! -f "$file_path" ]; then
            stdout -e "File not found: $file_path"
            return 1
        fi
        
        # Read the entire file content
        if ! secret_value=$(cat "$file_path"); then
            stdout -e "Failed to read file: $file_path"
            return 1
        fi
        
        if [ -z "$secret_value" ]; then
            stdout -e "File is empty: $file_path"
            return 1
        fi
        
        stdout -i "Reading secret value from file: $file_path"
    elif [ -z "$secret_value" ]; then
        stdin secret_value "Enter secret value" --hidden
    fi
    
    if [ -z "$secret_value" ]; then
        stdout -e "Secret value cannot be empty"
        return 1
    fi
    
    sdk_fac_sec_encrypt_and_store_secret "$secret_name" "$secret_value" "$key"
    if [ -n "$file_path" ]; then
        stdout -l "Secret '$secret_name' added successfully from file: $file_path"
    else
        stdout -l "Secret '$secret_name' added successfully"
    fi
}

# Export a single secret by name (returns just the value)
# This function is non-interactive and expects all validations to be done beforehand
sdk_fac_sec_export() {
    sdk_fac_sec_check_openssl || return 1
    sdk_fac_sec_validate_key_for_operation || return 1

    if [ -z "$1" ]; then
        stdout -e "Secret name required" >&2
        stdout -i "Usage: D secret export <secret_name>" >&2
        return 1
    fi

    local secret_name="$1"
    
    # Simple checks without interaction
    if ! sdk_fac_sec_check_openssl; then
        stdout -e "OpenSSL not available - required for secret encryption" >&2
        return 1
    fi
    
    if ! sdk_fac_sec_secret_exists "$secret_name"; then
        stdout -e "Secret '$secret_name' not found" >&2
        return 1
    fi
    
    if ! sdk_fac_sec_is_key_configured; then
        stdout -e "No encryption key configured" >&2
        if confirm "Would you like to set the encryption key now?"; then
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
        stdout -e "Failed to decrypt secret '$secret_name'" >&2
        return 1
    fi
}

# Show all secrets in a readable format
sdk_fac_sec_show_secrets() {
    sdk_fac_sec_check_openssl || return 1
    sdk_fac_sec_validate_key_for_operation || return 1

    local show_values=false
    
    # Parse arguments for flags
    while [ $# -gt 0 ]; do
        case "$1" in
            --unmask)
                show_values=true
                shift
                ;;
            -*)
                stdout -e "Unknown flag: $1"
                stdout -i "Usage: D secret show [--unmask]"
                return 1
                ;;
            *)
                stdout -e "Unexpected argument: $1"
                stdout -i "Usage: D secret show [--unmask]"
                return 1
                ;;
        esac
    done

    if ! sdk_fac_sec_secrets_exist; then
        stdout -w "No secrets found"
        return 0
    fi
    
    local key=$(sdk_fac_sec_get_encryption_key)
    local secret_count=0
    
    echo
    
    # Process and display each secret directly
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            local secret_name=$(basename "$secret_file")
            local encrypted_value=$(sdk_fac_sec_read_secret_file "$secret_name")
            local decrypted_value=$(sdk_fac_sec_decrypt_data "$encrypted_value" "$key")

            if [ $? -eq 0 ] && [ -n "$decrypted_value" ]; then
                # Display secret name in white
                printf "$(ansi "97" "%s")\n" "$secret_name"
                
                # Display secret value based on show_values flag
                if [ "$show_values" = true ]; then
                    # Show actual value in darker gray
                    printf "$(ansi "2;30" "%s")\n\n" "$decrypted_value"
                else
                    # Hide value
                    printf "$(ansi "8;30" "%s")\n\n" "$decrypted_value"
                fi
                
                secret_count=$((secret_count + 1))
            else
                stdout -w "Failed to decrypt secret '$secret_name'"
            fi
        fi
    done

    # Display summary if we have any secrets
    if [ $secret_count -gt 0 ]; then
        printf "\n"
        printf "$(ansi "2;90" "Total: %d secrets")\n" "$secret_count"
        if [ "$show_values" = false ]; then
            printf "$(ansi "2;90" "Use --unmask to display actual values")\n"
        fi
        printf "$(ansi "2;90" "To export a secret as environment variables:")\n"
        printf "$(ansi "2;90" "export SECRET_NAME=\"\$(\$D_CLI_STUB secret export 'SECRET_NAME')\"")\n"
    else
        stdout -w "No secrets were displayed"
    fi
}

# Remove a secret
sdk_fac_sec_remove_secret() {
    if [ -z "$1" ]; then
        stdout -e "Secret name required"
        stdout -i "Usage: D secret remove <secret_name>"
        return 1
    fi
    
    local secret_name="$1"
    
    if ! sdk_fac_sec_secret_exists "$secret_name"; then
        stdout -e "Secret '$secret_name' not found"
        return 1
    fi
    
    if confirm "Are you sure you want to remove secret '$secret_name'?"; then
        local secret_file=$(sdk_fac_sec_secret_file_path "$secret_name")
        rm "$secret_file"
        stdout -o "Secret '$secret_name' removed"
    else
        stdout -i "Operation cancelled"
    fi
}

# Check if secrets system is available
# Usage: sdk_fac_sec_cmd_check_availability [--quiet]
sdk_fac_sec_cmd_check_availability() {
    local quiet_flag=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --quiet|-q)
                quiet_flag=true
                ;;
            *)
                stdout -e "sdk_fac_sec_cmd_check_availability: Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if [ "$quiet_flag" != "true" ]; then
        stdout -i --processing "Checking secrets system availability"
    fi
    
    # Check OpenSSL availability
    if ! sdk_fac_sec_check_openssl; then
        if [ "$quiet_flag" != "true" ]; then
            stdout -e "OpenSSL not available - required for secret encryption"
        fi
        return 1
    fi
    
    # Check if secrets directory exists
    if [ ! -d "$SECRETS_DIR" ]; then
        if [ "$quiet_flag" != "true" ]; then
            stdout -w "Secrets directory does not exist: $SECRETS_DIR"
            stdout -i "Will be created when first secret is added"
        fi
    fi
    
    if [ "$quiet_flag" != "true" ]; then
        stdout -s "Secrets system is available"
        stdout -i "Secrets Directory: $SECRETS_DIR"
        stdout -i "Encryption: AES-256-CBC with auto-generated keys"
    fi
    
    return 0
}

# Validate and prepare a secret (interactive)
# Usage: sdk_fac_sec_cmd_validate_secret <secret_name>
sdk_fac_sec_cmd_validate_secret() {
    local secret_name="$1"

    if [ -z "$secret_name" ]; then
        stdout -e "Secret name required"
        stdout -i "Usage: secret validate <secret_name>"
        return 1
    fi
    shift
    
    # Use the existing validation function
    if sdk_fac_sec_validate_and_prepare_secret_interactive "$secret_name"; then
        return 0
    else
        return 1
    fi
}

# Check if a secret exists (non-interactive)
# Usage: sdk_fac_sec_cmd_secret_exists <secret_name> [--quiet]
sdk_fac_sec_cmd_secret_exists() {
    local secret_name="$1"
    local quiet_flag=false
    
    if [ -z "$secret_name" ]; then
        stdout -e "Secret name required"
        stdout -i "Usage: secret exists <secret_name>"
        return 1
    fi
    shift
    
    # Parse remaining arguments
    for arg in "$@"; do
        case $arg in
            --quiet|-q)
                quiet_flag=true
                ;;
            *)
                stdout -e "sdk_fac_sec_cmd_secret_exists: Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if sdk_fac_sec_secret_exists "$secret_name"; then
        if [ "$quiet_flag" != "true" ]; then
            stdout -s "Secret '$secret_name' exists"
        fi
        return 0
    else
        if [ "$quiet_flag" != "true" ]; then
            stdout -i "Secret '$secret_name' does not exist"
        fi
        return 1
    fi
}
