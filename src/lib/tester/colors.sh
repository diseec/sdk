#!/bin/bash
# Color definitions for test output

# ANSI color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export WHITE='\033[1;37m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m' # No Color

# Semantic color aliases
export COLOR_SUCCESS="$GREEN"
export COLOR_ERROR="$RED"
export COLOR_WARNING="$YELLOW"
export COLOR_INFO="$BLUE"
export COLOR_HIGHLIGHT="$CYAN"
export COLOR_MUTED="$DIM"

# Function to check if colors should be used
should_use_colors() {
    # Use colors if stdout is a terminal and not explicitly disabled
    if [ -t 1 ] && [ "${NO_COLOR:-}" != "1" ] && [ "${TERM:-}" != "dumb" ]; then
        return 0
    else
        return 1
    fi
}

# Disable colors if not appropriate
if ! should_use_colors; then
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" MAGENTA="" WHITE="" BOLD="" DIM="" NC=""
    COLOR_SUCCESS="" COLOR_ERROR="" COLOR_WARNING="" COLOR_INFO="" COLOR_HIGHLIGHT="" COLOR_MUTED=""
fi
