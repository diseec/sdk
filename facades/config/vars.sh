#!/bin/bash

readonly DEFAULT_SCOPE="repository"

# =============================================================================
# FUNDAMENTAL ARCHITECTURAL
# =============================================================================

readonly CLONES_DIR_NAME="repositories"

sdk_fac_con_get_suggest_ctx_dir() {
    local repo_name="${1:-$D_REPO_NAME}"
    
    if [ -z "$repo_name" ]; then
        logit -e "Repository name is undefined. Cannot determine context directory."
        return 1
    fi
    
    echo "$D_ORG_DIR/$CLONES_DIR_NAME/$repo_name/$repo_name"
}

sdk_fac_con_get_scope_ctx_dir() {
    if [ -z "$D_REPO_NAME" ]; then
        logit -e "Repository name (D_REPO_NAME) is undefined. Cannot determine context scope directory."
        return 1
    fi
    
    local ctx_dir=$(sdk_fac_con_get_suggest_ctx_dir)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "$ctx_dir/.$D_SDK_NAME"
}
readonly SCOPE_CTX_DIR="$(sdk_fac_con_get_scope_ctx_dir)"

sdk_fac_con_get_scope_repo_dir() {
    if [ -z "$D_REPO_NAME" ]; then
        logit -e "Repository name (D_REPO_NAME) is undefined. Cannot determine repository scope directory."
        return 1
    fi
    
    echo "$D_ORG_DIR/$CLONES_DIR_NAME/$D_REPO_NAME"
}
readonly SCOPE_REPO_DIR="$(sdk_fac_con_get_scope_repo_dir)"

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