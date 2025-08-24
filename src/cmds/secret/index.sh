#!/bin/bash

# Secrets manager for secure storage and retrieval of environment variables
# Uses OpenSSL for encryption/decryption with auto-generated key

SECRETS_DIR="$ROOT_DIR/secrets"
mkdir -p "$SECRETS_DIR"

. $KIT_SRC_DIR/cmds/secret/core.sh
. $KIT_SRC_DIR/cmds/secret/encryption.sh
. $KIT_SRC_DIR/cmds/secret/interactions.sh
. $KIT_SRC_DIR/cmds/secret/key.sh
. $KIT_SRC_DIR/cmds/secret/secret.sh
. $KIT_SRC_DIR/cmds/secret/helpers.sh
. $KIT_SRC_DIR/cmds/secret/cmds.sh