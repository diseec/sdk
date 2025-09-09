#!/bin/bash
# Secret Module - Command Implementations
# CLI command implementations for secret management

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
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if [ "$quiet_flag" != "true" ]; then
        logit -i "Checking secrets system availability..."
    fi
    
    # Check OpenSSL availability
    if ! sdk_fac_sec_check_openssl; then
        if [ "$quiet_flag" != "true" ]; then
            logit -e "OpenSSL not available - required for secret encryption"
        fi
        return 1
    fi
    
    # Check if secrets directory exists
    if [ ! -d "$SECRETS_DIR" ]; then
        if [ "$quiet_flag" != "true" ]; then
            logit -w "Secrets directory does not exist: $SECRETS_DIR"
            logit -i "Will be created when first secret is added"
        fi
    fi
    
    if [ "$quiet_flag" != "true" ]; then
        logit -s "Secrets system is available"
        logit -i "Secrets Directory: $SECRETS_DIR"
        logit -i "Encryption: AES-256-CBC with auto-generated keys"
    fi
    
    return 0
}

# Validate and prepare a secret (interactive)
# Usage: sdk_fac_sec_cmd_validate_secret <secret_name> [--quiet]
sdk_fac_sec_cmd_validate_secret() {
    local secret_name="$1"
    local quiet_flag=false
    
    if [ -z "$secret_name" ]; then
        logit -e "Secret name required"
        logit -i "Usage: secret validate <secret_name>"
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
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if [ "$quiet_flag" != "true" ]; then
        logit -i "Validating secret '$secret_name'..."
    fi
    
    # Use the existing validation function
    if sdk_fac_sec_validate_and_prepare_secret_interactive "$secret_name"; then
        if [ "$quiet_flag" != "true" ]; then
            logit -s "Secret '$secret_name' is valid and ready to use"
        fi
        return 0
    else
        if [ "$quiet_flag" != "true" ]; then
            logit -e "Failed to validate secret '$secret_name'"
        fi
        return 1
    fi
}

# Initialize and ensure a secret exists (interactive)
# Usage: sdk_fac_sec_cmd_init_secret <secret_name> [--quiet]
sdk_fac_sec_cmd_init_secret() {
    local secret_name="$1"
    local quiet_flag=false
    
    if [ -z "$secret_name" ]; then
        logit -e "Secret name required"
        logit -i "Usage: secret init <secret_name>"
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
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if [ "$quiet_flag" != "true" ]; then
        logit -i "Initializing secret '$secret_name'..."
    fi
    
    # Check if secret already exists and is valid
    if sdk_fac_sec_secret_exists "$secret_name" && sdk_fac_sec_validate_and_prepare_secret_interactive "$secret_name" >/dev/null 2>&1; then
        if [ "$quiet_flag" != "true" ]; then
            logit -s "Secret '$secret_name' already exists and is valid"
        fi
        return 0
    fi
    
    # Initialize the secret system and add the secret
    if sdk_fac_sec_validate_and_prepare_secret_interactive "$secret_name"; then
        if [ "$quiet_flag" != "true" ]; then
            logit -s "Secret '$secret_name' initialized successfully"
        fi
        return 0
    else
        if [ "$quiet_flag" != "true" ]; then
            logit -e "Failed to initialize secret '$secret_name'"
        fi
        return 1
    fi
}

# Check if a secret exists (non-interactive)
# Usage: sdk_fac_sec_cmd_secret_exists <secret_name> [--quiet]
sdk_fac_sec_cmd_secret_exists() {
    local secret_name="$1"
    local quiet_flag=false
    
    if [ -z "$secret_name" ]; then
        logit -e "Secret name required"
        logit -i "Usage: secret exists <secret_name>"
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
                logit -e "Unknown argument: $arg"
                return 1
                ;;
        esac
    done
    
    if sdk_fac_sec_secret_exists "$secret_name"; then
        if [ "$quiet_flag" != "true" ]; then
            logit -s "Secret '$secret_name' exists"
        fi
        return 0
    else
        if [ "$quiet_flag" != "true" ]; then
            logit -i "Secret '$secret_name' does not exist"
        fi
        return 1
    fi
}
