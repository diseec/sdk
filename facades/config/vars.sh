#!/bin/bash

readonly DEFAULT_SCOPE="context"

# =============================================================================
# FUNDAMENTAL ARCHITECTURAL
# =============================================================================

readonly CLONES_DIR_NAME="repositories"

sdk_fac_con_get_suggest_ctx_dir() {
    local repo_name="${1:-$D_REPO_NAME}"
    if [ -d "$D_CTX_DIR" ]; then
        echo "$D_CTX_DIR"
    else
        echo "$D_ORG_DIR/$CLONES_DIR_NAME/$repo_name/$repo_name"
    fi
}

readonly SCOPE_CTX_DIR="$(sdk_fac_con_get_suggest_ctx_dir)/.$D_SDK_NAME"
readonly SCOPE_REPO_DIR="$D_ORG_DIR/$CLONES_DIR_NAME/$D_REPO_NAME"
readonly SCOPE_USER_DIR="$D_ORG_DIR"

# =============================================================================
# CONFIGURATION CONSTANTS AND TYPES
# =============================================================================

# Configuration file names and structure
readonly SCOPE_CTX_FILE="$SCOPE_CTX_DIR/config.yaml"
readonly SCOPE_REPO_FILE="$SCOPE_REPO_DIR/config.yaml"
readonly SCOPE_USER_FILE="$SCOPE_USER_DIR/config.yaml"

# Configuration scopes in order of precedence (highest to lowest)
readonly CONFIG_SCOPES="context repository user"

# =============================================================================
# CACHE CONSTANTS
# =============================================================================

readonly CACHE_CTX_DIR="$SCOPE_CTX_DIR/.cache"
readonly CACHE_REPO_DIR="$SCOPE_REPO_DIR/.cache"
readonly CACHE_USER_DIR="$SCOPE_USER_DIR/.cache"