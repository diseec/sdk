#!/bin/bash

# Source the tester framework
source_once "$D_SDK_DIR/facades/tester/index.sh"

export TESTER_VERBOSE=false
export TESTER_FAIL_FAST=false
export TESTER_QUIET=false
export TESTER_DRY_RUN=false

if [ $# -eq 0 ]; then set -- run --verbose --fail-fast; fi

ARGS=""; for arg in "$@"; do case "$arg" in
    # -x=*|--x=*) X="${arg#*=}";;
    --verbose|-v) export TESTER_VERBOSE=true ;;
    --fail-fast) export TESTER_FAIL_FAST=true ;;
    --quiet|-q) export TESTER_QUIET=true ;;
    --dry-run) export TESTER_DRY_RUN=true ;;
*) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

# Main CLI command handler
c=$1; shift; case $c in
    run)
        # Run tests with optional filter
        sdk_tester_run_tests "$@"
        ;;
    lis|list)
        # List all discoverable tests
        sdk_tester_list_tests "$@"
        ;;
    dis|discover)
        # Discover tests and show paths
        sdk_tester_discover_tests "$@"
        ;;
    fil|filter)
        # Filter tests by pattern and run them
        if [ $# -eq 0 ]; then
            logit -e "Filter pattern required. Usage: tester filter <pattern>"
            return 1
        fi
        sdk_tester_filter_and_run "$@"
        ;;
    cle|clean)
        # Clean test artifacts and temporary files
        sdk_tester_clean_artifacts
        ;;
    --help|-h|hel|help)
        display_help "" "" \
            "$(ansi "1;90" "$(capitalize 'USAGE')")                        " "[$D_CLI_GLOBAL_NAME tester]/[bash $D_CLI_LOCAL_NAME tester] [command] [options]" \
            "                             " "$(ansi "2;90" "Simple and elegant testing framework for shell scripts")" \
            "" "" \
            "$(ansi "1;90" "$(capitalize 'TEST COMMANDS')")" "" \
            "    run|r [pattern]      " "Run all tests or filter by pattern" \
            "    list|l [pattern]     " "List all discoverable test files" \
            "    discover|d           " "Show test discovery paths and statistics" \
            "    filter|f <pattern>   " "Filter and run tests matching pattern" \
            "    clean|c              " "Clean test artifacts and temporary files" \
            "" "" \
            "$(ansi "1;90" "$(capitalize 'OPTIONS')")" "" \
            "    --verbose|-v         " "Show detailed test output and timing" \
            "    --fail-fast          " "Stop on first test failure" \
            "    --quiet|-q           " "Minimal output, show only results summary" \
            "    --dry-run            " "Show what would be tested without running" \
            "" "" \
            "$(ansi "1;90" "$(capitalize 'EXAMPLES')")" "" \
            "    $D_CLI_GLOBAL_NAME tester run                    " "$(ansi "2;90" "Run all tests in the project")" \
            "    $D_CLI_GLOBAL_NAME tester run auth               " "$(ansi "2;90" "Run tests containing 'auth' in name/path")" \
            "    $D_CLI_GLOBAL_NAME tester list                   " "$(ansi "2;90" "List all discoverable test files")" \
            "    $D_CLI_GLOBAL_NAME tester filter validation      " "$(ansi "2;90" "Filter and run validation tests")" \
            "    $D_CLI_GLOBAL_NAME tester run --verbose          " "$(ansi "2;90" "Run tests with detailed output")" \
            "    $D_CLI_GLOBAL_NAME tester run --fail-fast        " "$(ansi "2;90" "Stop testing on first failure")" \
            "" "" \
            "$(ansi "1;90" "$(capitalize 'TEST FILE STRUCTURE')")" "" \
            "    Test files must end with '.test.sh'             " "$(ansi "2;90" "e.g., auth.test.sh, utils.test.sh")" \
            "    Tests are discovered recursively from project root" "$(ansi "2;90" "Searches all subdirectories")" \
            "    Each test file should define test functions      " "$(ansi "2;90" "Functions starting with 'test_'")" \
            "" "" \
            "$(ansi "1;90" "$(capitalize 'ASSERTION FUNCTIONS')")" "" \
            "    assert_equals <expected> <actual>                " "$(ansi "2;90" "Assert two values are equal")" \
            "    assert_not_equals <expected> <actual>            " "$(ansi "2;90" "Assert two values are not equal")" \
            "    assert_contains <haystack> <needle>              " "$(ansi "2;90" "Assert string contains substring")" \
            "    assert_not_contains <haystack> <needle>          " "$(ansi "2;90" "Assert string does not contain substring")" \
            "    assert_file_exists <path>                        " "$(ansi "2;90" "Assert file exists")" \
            "    assert_file_not_exists <path>                    " "$(ansi "2;90" "Assert file does not exist")" \
            "    assert_command_success <command>                 " "$(ansi "2;90" "Assert command exits with code 0")" \
            "    assert_command_fails <command>                   " "$(ansi "2;90" "Assert command exits with non-zero code")" \
            "    assert_matches <value> <pattern>                 " "$(ansi "2;90" "Assert value matches regex pattern")" \
            "    assert_greater_than <value> <threshold>          " "$(ansi "2;90" "Assert numeric value is greater than threshold")" \
            "    assert_less_than <value> <threshold>             " "$(ansi "2;90" "Assert numeric value is less than threshold")" \
            "    assert_empty <value>                             " "$(ansi "2;90" "Assert value is empty")" \
            "    assert_not_empty <value>                         " "$(ansi "2;90" "Assert value is not empty")" \
            "" "" \
            "$(ansi "1;33" "$(capitalize 'EXTENDED ASSERTIONS FOR SECRETS')")" "" \
            "    assert_valid_hex_key <value> [length]            " "$(ansi "2;90" "Assert value is valid hex key (default 64 chars)")" \
            "    assert_contains_error <output>                   " "$(ansi "2;90" "Assert output contains error indicators")" \
            "    assert_contains_success <output>                 " "$(ansi "2;90" "Assert output contains success indicators")" \
            "    assert_min_length <value> <min>                  " "$(ansi "2;90" "Assert value has minimum length")" \
            "    assert_max_length <value> <max>                  " "$(ansi "2;90" "Assert value has maximum length")" \
            "" "" \
            "$@"
        ;;
    *)
        if [[ -n "$c" ]]; then 
            logit -e "Unknown test command: '$c'"
            logit -i "Run '$D_CLI_GLOBAL_NAME test help' for available commands"
            return 1
        fi
        cli_ctx test help
        ;;
esac
