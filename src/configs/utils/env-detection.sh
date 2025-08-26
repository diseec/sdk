#!/bin/bash

# =============================================================================
# ENVIRONMENT DETECTION UTILITIES
# =============================================================================
# Functions to detect various environment states

is_online() {
    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}

is_in_container() {
    if [ -f "/.dockerenv" ] || [ "$IS_IN_CONTAINER" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}

is_monorepo() {
    if [ -d "$ROOT_DIR/services" ] && [ "$(ls -A "$ROOT_DIR/services" 2>/dev/null)" ]; then
        echo "true"
    else
        echo "false"
    fi
}

has_submodules() {
    if [ -f "$ROOT_DIR/.gitmodules" ] && [ -s "$ROOT_DIR/.gitmodules" ]; then
        echo "true"
    else
        echo "false"
    fi
}

get_kit_version() {
    if [ -f "$KIT_DIR/package.json" ]; then
        grep '"version"' "$KIT_DIR/package.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/'
    else
        echo "unknown"
    fi
}
