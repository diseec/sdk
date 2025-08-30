#!/bin/bash

# =============================================================================
# ENVIRONMENT DETECTION UTILITIES
# =============================================================================
# Functions to detect various environment states

env_uti_is_in_container() {
    if [ -f "/.dockerenv" ] || [ "$IS_IN_CONTAINER" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}

env_uti_has_submodules() {
    if [ -f "$ROOT_DIR/.gitmodules" ] && [ -s "$ROOT_DIR/.gitmodules" ]; then
        echo "true"
    else
        echo "false"
    fi
}

env_uti_get_kit_version() {
    if [ -f "$KIT_DIR/package.json" ]; then
        grep '"version"' "$KIT_DIR/package.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/'
    else
        echo "unknown"
    fi
}
