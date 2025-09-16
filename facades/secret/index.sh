#!/bin/bash

# Secrets manager for secure storage and retrieval of environment variables
# Uses OpenSSL for encryption/decryption with auto-generated key

source "$D_SDK_DIR/facades/secret/core.sh"
source "$D_SDK_DIR/facades/secret/encryption.sh"
source "$D_SDK_DIR/facades/secret/interactions.sh"
source "$D_SDK_DIR/facades/secret/key.sh"
source "$D_SDK_DIR/facades/secret/secret.sh"
source "$D_SDK_DIR/facades/secret/helpers.sh"
source "$D_SDK_DIR/facades/secret/cmds.sh"

readonly SECRETS_DIR="$(sdk_fac_sec_get_secrets_dir)"