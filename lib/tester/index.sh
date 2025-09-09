#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ DISEEC SDK TESTING FRAMEWORK                                            ┃
# ┃ A simple, elegant, and modular testing framework for shell scripts      ┃
# ┃                                                                         ┃
# ┃ Features:                                                               ┃
# ┃ • Beautiful and easy assertions                                         ┃
# ┃ • Auto-discovery of *.test.sh files                                     ┃
# ┃ • Elegant filtering and running capabilities                            ┃
# ┃ • Consistent styling following SDK guidelines                           ┃
# ┃ • Modular architecture with clean API                                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Source core testing components
source_once "$D_SDK_DIR/lib/tester/core/assertions.sh"
source_once "$D_SDK_DIR/lib/tester/core/registry.sh"
source_once "$D_SDK_DIR/lib/tester/core/helpers.sh"
source_once "$D_SDK_DIR/lib/tester/core/runner.sh"
source_once "$D_SDK_DIR/lib/tester/core/discovery.sh"
source_once "$D_SDK_DIR/lib/tester/core/reporter.sh"
source_once "$D_SDK_DIR/lib/tester/core/suite.sh"

# Initialize tester framework
sdk_tester_initialize() {
    export D_ENV="TESTING"; 

    # Set up global test state variables
    export TESTER_TOTAL_TESTS=0
    export TESTER_PASSED_TESTS=0
    export TESTER_FAILED_TESTS=0
    export TESTER_SKIPPED_TESTS=0
    export TESTER_CURRENT_SUITE=""
    export TESTER_CURRENT_TEST=""
    export TESTER_START_TIME=""
    export TESTER_VERBOSE=${TESTER_VERBOSE:-false}
    export TESTER_FAIL_FAST=${TESTER_FAIL_FAST:-false}
    
    # Color configuration for test output
    export TESTER_COLOR_PASS="32"      # Green
    export TESTER_COLOR_FAIL="31"      # Red  
    export TESTER_COLOR_SKIP="33"      # Yellow
    export TESTER_COLOR_INFO="34"      # Blue
    export TESTER_COLOR_SUITE="96"     # Cyan
    export TESTER_COLOR_HEADER="1;90"  # Bold Gray
    export TESTER_COLOR_DIM="2;90"     # Dim Gray

    # Ensure D command called in tests point to the local D since is a global
    D() {
        (env D_SDK_DIR="$D_SDK_DIR" "$D_SDK_DIR/$D_CLI_GLOBAL_NAME" "$@")
    }
}

# Initialize on source
sdk_tester_initialize
