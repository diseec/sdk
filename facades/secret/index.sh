#!/bin/bash

# Secrets manager for secure storage and retrieval of environment variables
# Uses OpenSSL for encryption/decryption with auto-generated key

SECRETS_DIR="$D_CTX_DIR/secrets"

source "$D_SDK_DIR/facades/secret/core.sh"
source "$D_SDK_DIR/facades/secret/encryption.sh"
source "$D_SDK_DIR/facades/secret/interactions.sh"
source "$D_SDK_DIR/facades/secret/key.sh"
source "$D_SDK_DIR/facades/secret/secret.sh"
source "$D_SDK_DIR/facades/secret/helpers.sh"
source "$D_SDK_DIR/facades/secret/cmds.sh"

# Load command implementations
source "$D_SDK_DIR/facades/secret/cmds/commands.sh"
