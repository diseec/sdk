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
source_once "$D_SDK_DIR/facades/tester/core/assertions.sh"
source_once "$D_SDK_DIR/facades/tester/core/registry.sh"
source_once "$D_SDK_DIR/facades/tester/core/helpers.sh"
source_once "$D_SDK_DIR/facades/tester/core/runner.sh"
source_once "$D_SDK_DIR/facades/tester/core/discovery.sh"
source_once "$D_SDK_DIR/facades/tester/core/reporter.sh"
source_once "$D_SDK_DIR/facades/tester/core/suite.sh"

# Initialize tester framework
sdk_tester_initialize() { 
    
    if [ "$IS_TESTING_COMPOSE_FILE" != "true" ]; then
        stdout -e "Test runner requires test compose file"
        exit 1
    fi

    # Disable TTY functionality during tests
    export IS_TTY_AVAILABLE="false"
    export D_GLOB_LOG_LEVEL="VERBOSE"
    # export D_GLOB_DEBUG="false"

    export TESTER_RESULT_FILE_NAME=".test_result"
    export TESTER_LOG_FILE_NAME=".test_logs_XXXXXX"
    export TESTER_FAILURE_KEY="FAILED:"

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
}

# Initialize on source
sdk_tester_initialize
