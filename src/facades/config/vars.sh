#!/bin/bash

readonly DEFAULT_SCOPE="work"

# =============================================================================
# FUNDAMENTAL ARCHITECTURAL
# =============================================================================

readonly CLONES_DIR_NAME="repositories"

src_fac_con_get_scope_work_dir() {
    local repo_name="$1"
    if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
        echo "$WORK_DIR/.$SDK_NAME"
    else
        echo "$ORG_DIR/$CLONES_DIR_NAME/$repo_name/$repo_name"
    fi
}

readonly SCOPE_WORK_DIR="$(src_fac_con_get_scope_work_dir "$REPO_NAME")"
readonly SCOPE_REPO_DIR="$ORG_DIR/$CLONES_DIR_NAME/$REPO_NAME"
readonly SCOPE_USER_DIR="$ORG_DIR"

# =============================================================================
# CONFIGURATION CONSTANTS AND TYPES
# =============================================================================

# Configuration file names and structure
readonly SCOPE_WORK_FILE="$SCOPE_WORK_DIR/config.yaml"
readonly SCOPE_REPO_FILE="$SCOPE_REPO_DIR/config.yaml"
readonly SCOPE_USER_FILE="$SCOPE_USER_DIR/config.yaml"

# Configuration scopes in order of precedence (highest to lowest)
readonly CONFIG_SCOPES="work repo user"

# =============================================================================
# CACHE CONSTANTS
# =============================================================================

readonly CACHE_WORK_DIR="$SCOPE_WORK_DIR/.cache"
readonly CACHE_REPO_DIR="$SCOPE_REPO_DIR/.cache"
readonly CACHE_USER_DIR="$SCOPE_USER_DIR/.cache"