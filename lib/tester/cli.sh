#!/bin/bash

if [ $# -eq 0 ]; then set -- run; fi

# Source the tester framework
source_once "$D_SDK_DIR/lib/tester/index.sh"

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
            exit 1
        fi
        sdk_tester_filter_and_run "$@"
        ;;
    cle|clean)
        # Clean test artifacts and temporary files
        sdk_tester_clean_artifacts
        ;;
    --help|-h)
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
            "    assert_file_exists <path>                        " "$(ansi "2;90" "Assert file exists")" \
            "    assert_command_success <command>                 " "$(ansi "2;90" "Assert command exits with code 0")" \
            "    assert_command_fails <command>                   " "$(ansi "2;90" "Assert command exits with non-zero code")" \
            "" "" \
            "$@"
        ;;
    *)
        if [[ -n "$c" ]]; then 
            logit -e "Unknown tester command: '$c'"
            logit -i "Run '$D_CLI_GLOBAL_NAME tester help' for available commands"
            exit 1
        fi
        cli_ctx tester help
        ;;
esac
