#!/bin/bash

# Secrets manager for secure storage and retrieval of environment variables
# Uses OpenSSL for encryption/decryption with auto-generated key

SECRETS_DIR="$ROOT_DIR/secrets"

source "$KIT_SRC_DIR/facades/secret/core.sh"
source "$KIT_SRC_DIR/facades/secret/encryption.sh"
source "$KIT_SRC_DIR/facades/secret/interactions.sh"
source "$KIT_SRC_DIR/facades/secret/key.sh"
source "$KIT_SRC_DIR/facades/secret/secret.sh"
source "$KIT_SRC_DIR/facades/secret/helpers.sh"
source "$KIT_SRC_DIR/facades/secret/cmds.sh"
