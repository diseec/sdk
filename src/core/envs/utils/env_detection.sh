#!/bin/bash

# =============================================================================
# ENVIRONMENT DETECTION UTILITIES
# =============================================================================
# Functions to detect various environment states

src_cor_env_uti_is_in_container() {
    if [ -f "/.dockerenv" ] || [ "$IS_IN_CONTAINER" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}

src_cor_env_uti_has_submodules() {
    if [ -f "$WORK_DIR/.gitmodules" ] && [ -s "$WORK_DIR/.gitmodules" ]; then
        echo "true"
    else
        echo "false"
    fi
}

src_cor_env_uti_get_kit_version() {
    if [ -f "$SDK_DIR/package.json" ]; then
        grep '"version"' "$SDK_DIR/package.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/'
    else
        echo "unknown"
    fi
}

src_cor_env_uti_get_kit_target_dit() {
    if [ -z "$WORK_DIR_HOST" ]; then
        echo "$WORK_DIR"
    else
        echo "$WORK_DIR_HOST" # Is set when the command "D sdk" has executed
    fi
}
