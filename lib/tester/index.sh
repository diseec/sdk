#!/bin/bash
# Main entry point for the SDK testing framework
# This file bootstraps the testing environment and provides a unified interface

set -euo pipefail

# Detect script directory
TESTING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TESTING_DIR

# Ensure D_SDK_DIR is set
if [ -z "${D_SDK_DIR:-}" ]; then
    # Try to autodetect D_SDK_DIR if not set
    if [ -d "$TESTING_DIR/../../.." ]; then
        export D_SDK_DIR="$(cd "$TESTING_DIR/../../.." && pwd)"
    else
        echo "Error: D_SDK_DIR environment variable is not set and could not be autodetected" >&2
        exit 1
    fi
fi

# Execute the main test runner with all arguments
exec "$TESTING_DIR/bin/run.sh" "$@"
