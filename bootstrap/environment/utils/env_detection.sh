#!/bin/bash

# =============================================================================
# ENVIRONMENT DETECTION UTILITIES
# =============================================================================
# Functions to detect various environment states

sdk_boo_env_uti_is_in_container() {
    if [ -f "/.dockerenv" ] || [ "$D_IS_IN_CONTAINER" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}

sdk_boo_env_uti_has_submodules() {
    if [ -f "$D_CTX_DIR/.gitmodules" ] && [ -s "$D_CTX_DIR/.gitmodules" ]; then
        echo "true"
    else
        echo "false"
    fi
}

sdk_boo_env_uti_get_kit_version() {
    if [ -f "$D_SDK_DIR/package.json" ]; then
        grep '"version"' "$D_SDK_DIR/package.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/'
    else
        echo "unknown"
    fi
}

sdk_boo_env_uti_get_kit_target_dir() {
    if [ -z "$D_TARGET_CTX_DIR" ]; then
        echo "$D_CTX_DIR"
    else
        echo "$D_TARGET_CTX_DIR" # Is set when the command "D sdk" has executed
    fi
}
