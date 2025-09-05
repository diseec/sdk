#!/bin/bash

readonly DEFAULT_SCOPE="work"

# =============================================================================
# FUNDAMENTAL ARCHITECTURAL
# =============================================================================

readonly CLONES_DIR_NAME="repositories"

src_fac_con_get_scope_ctx_dir() {
    local repo_name="$1"
    if [ -n "$D_CTX_DIR" ] && [ -d "$D_CTX_DIR" ]; then
        echo "$D_CTX_DIR/.$D_SDK_NAME"
    else
        echo "$D_ORG_DIR/$CLONES_DIR_NAME/$repo_name/$repo_name"
    fi
}

readonly SCOPE_CTX_DIR="$(src_fac_con_get_scope_ctx_dir "$D_REPO_NAME")"
readonly SCOPE_REPO_DIR="$D_ORG_DIR/$CLONES_DIR_NAME/$D_REPO_NAME"
readonly SCOPE_USER_DIR="$D_ORG_DIR"

# =============================================================================
# CONFIGURATION CONSTANTS AND TYPES
# =============================================================================

# Configuration file names and structure
readonly SCOPE_WORK_FILE="$SCOPE_CTX_DIR/config.yaml"
readonly SCOPE_REPO_FILE="$SCOPE_REPO_DIR/config.yaml"
readonly SCOPE_USER_FILE="$SCOPE_USER_DIR/config.yaml"

# Configuration scopes in order of precedence (highest to lowest)
readonly CONFIG_SCOPES="work repo user"

# =============================================================================
# CACHE CONSTANTS
# =============================================================================

readonly CACHE_CTX_DIR="$SCOPE_CTX_DIR/.cache"
readonly CACHE_REPO_DIR="$SCOPE_REPO_DIR/.cache"
readonly CACHE_USER_DIR="$SCOPE_USER_DIR/.cache"