#!/bin/bash

# Secrets manager for secure storage and retrieval of environment variables
# Uses OpenSSL for encryption/decryption with auto-generated key

SECRETS_DIR="$WORK_DIR/secrets"

source "$SDK_SRC_DIR/facades/secret/core.sh"
source "$SDK_SRC_DIR/facades/secret/encryption.sh"
source "$SDK_SRC_DIR/facades/secret/interactions.sh"
source "$SDK_SRC_DIR/facades/secret/key.sh"
source "$SDK_SRC_DIR/facades/secret/secret.sh"
source "$SDK_SRC_DIR/facades/secret/helpers.sh"
source "$SDK_SRC_DIR/facades/secret/cmds.sh"
