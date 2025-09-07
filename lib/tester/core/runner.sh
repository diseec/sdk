#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST RUNNER ENGINE                                                      ┃
# ┃ Executes test files and manages test execution lifecycle                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Parse command line options for test runner
_sdk_tester_parse_options() {
    export TESTER_VERBOSE=false
    export TESTER_FAIL_FAST=false
    export TESTER_QUIET=false
    export TESTER_DRY_RUN=false
    
    local args=()
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose|-v)
                export TESTER_VERBOSE=true
                shift
                ;;
            --fail-fast)
                export TESTER_FAIL_FAST=true
                shift
                ;;
            --quiet|-q)
                export TESTER_QUIET=true
                shift
                ;;
            --dry-run)
                export TESTER_DRY_RUN=true
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Return remaining arguments
    printf '%s\n' "${args[@]}"
}

# Execute a single test file
_sdk_tester_run_test_file() {
    local test_file="$1"
    local search_root="${D_CTX_DIR:-$(pwd)}"
    local relative_path="${test_file#$search_root/}"
    
    TESTER_CURRENT_SUITE="$relative_path"
    
    # Show file header (without newline, results will be on same line)
    sdk_tester_show_file_header "$test_file"
    
    if [ "$TESTER_DRY_RUN" = "true" ]; then
        printf " \033[90m(dry run)\033[0m\n"
        return 0
    fi
    
    # Store current test counts to calculate file-specific results
    local file_start_total=$TESTER_TOTAL_TESTS
    local file_start_passed=$TESTER_PASSED_TESTS
    local file_start_failed=$TESTER_FAILED_TESTS
    local file_start_skipped=$TESTER_SKIPPED_TESTS
    
    # Source and execute the test file
    if [ -f "$test_file" ]; then
        # Before sourcing a new test file, unset any existing test functions
        # to avoid mixing tests between files
        local existing_test_functions
        existing_test_functions=$(declare -F | grep "declare -f test_" | sed 's/declare -f //')
        if [ -n "$existing_test_functions" ]; then
            while IFS= read -r func_name; do
                unset -f "$func_name" 2>/dev/null || true
            done <<< "$existing_test_functions"
        fi
        
        # Source the test file in current shell to preserve test state
        source "$test_file"
        
        # Find and execute all test functions
        local test_functions
        test_functions=$(declare -F | grep "declare -f test_" | sed 's/declare -f //')
        
        if [ -z "$test_functions" ]; then
            printf " \033[33m[!]\033[0m \033[90mno test functions\033[0m\n"
            return 0
        fi
        
        # Run suite setup if defined
        if declare -f suite_setup >/dev/null 2>&1; then
            if ! suite_setup; then
                printf " \033[31m✖\033[0m \033[90msetup failed\033[0m\n"
                return 1
            fi
        fi
        
        # Execute each test function (using array to avoid subshell issues)
        local test_functions_array=()
        while IFS= read -r test_function; do
            if [ -n "$test_function" ]; then
                test_functions_array+=("$test_function")
            fi
        done <<< "$test_functions"
        
        # Now execute each test function in current shell
        for test_function in "${test_functions_array[@]}"; do
            TESTER_CURRENT_TEST="$test_function"
            
            # Show test function start in verbose mode
            if [ "$TESTER_VERBOSE" = "true" ]; then
                printf "    \033[90m→\033[0m \033[97m%s\033[0m" "$test_function"
            fi
            
            # Run test setup if defined
            if declare -f test_setup >/dev/null 2>&1; then
                test_setup
            fi
            
            # Execute the test function
            "$test_function"
            local test_exit_code=$?
            
            # Run test teardown if defined
            if declare -f test_teardown >/dev/null 2>&1; then
                test_teardown
            fi
            
            # Show test function completion in verbose mode
            if [ "$TESTER_VERBOSE" = "true" ]; then
                printf "\n"
            fi
            
            # Check if we should fail fast
            if [ $test_exit_code -ne 0 ] && [ "$TESTER_FAIL_FAST" = "true" ]; then
                return 1
            fi
        done
        
        # Run suite teardown if defined (always run)
        if declare -f suite_teardown >/dev/null 2>&1; then
            suite_teardown
            # Unset the suite_setup and suite_teardown functions to avoid carrying them to the next file
            unset -f suite_setup 2>/dev/null || true
            unset -f suite_teardown 2>/dev/null || true
        fi
        
        # Also unset test_setup and test_teardown functions
        if declare -f test_setup >/dev/null 2>&1; then
            unset -f test_setup 2>/dev/null || true
        fi
        
        if declare -f test_teardown >/dev/null 2>&1; then
            unset -f test_teardown 2>/dev/null || true
        fi
        
        local exit_code=$?
        if [ $exit_code -ne 0 ] && [ "$TESTER_FAIL_FAST" = "true" ]; then
            return $exit_code
        fi
    else
        printf " \033[31m✖\033[0m \033[90mnot found\033[0m\n"
        return 1
    fi
    
    # Calculate and display file-specific results compactly
    local file_total=$((TESTER_TOTAL_TESTS - file_start_total))
    local file_passed=$((TESTER_PASSED_TESTS - file_start_passed))
    local file_failed=$((TESTER_FAILED_TESTS - file_start_failed))
    local file_skipped=$((TESTER_SKIPPED_TESTS - file_start_skipped))
    
    echo ""

    # Show compact results on same line as file header
    sdk_tester_show_file_results "$file_passed" "$file_failed" "$file_skipped" "$file_total"
    
    echo ""
    
    return 0
}

# Main test runner function
sdk_tester_run_tests() {
    # Parse options and get remaining arguments
    local remaining_args
    _sdk_tester_parse_options "$@" # requires separate call to set env vars
    remaining_args=($(_sdk_tester_parse_options "$@"))
    local pattern="${remaining_args[0]:-}"
    
    # Initialize test state
    sdk_tester_initialize
    TESTER_START_TIME=$(date +%s)
    
    # Get test files
    local test_files
    test_files=$(_sdk_tester_get_test_files "${args[@]}")
    
    if [ -z "$test_files" ]; then
        local timestamp=$(date "+%H:%M:%S")
        if [ -n "${args[@]}" ]; then
            printf "\033[90m[%s]\033[0m\033[33m[!]\033[0m \033[90mNo tests match pattern:\033[0m \033[97m%s\033[0m\n" "$timestamp" "${args[@]}"
        else
            printf "\033[90m[%s]\033[0m\033[33m[!]\033[0m \033[90mNo test files found. Create\033[0m \033[97m*.test.sh\033[0m \033[90mfiles to start\033[0m\n" "$timestamp"
        fi
        return 1
    fi
    
    local test_count
    test_count=$(echo "$test_files" | wc -l | tr -d ' ')
    
    # Show compact header
    sdk_tester_show_header "$test_count" "${args[@]}"
    
    # Run tests (convert to array to avoid subshell issues)
    local failed_files=()
    local test_files_array=()
    
    while IFS= read -r test_file; do
        if [ -n "$test_file" ]; then
            test_files_array+=("$test_file")
        fi
    done <<< "$test_files"
    
    # Execute each test file in current shell
    for test_file in "${test_files_array[@]}"; do
        if ! _sdk_tester_run_test_file "$test_file"; then
            failed_files+=("$test_file")
            if [ "$TESTER_FAIL_FAST" = "true" ]; then
                break
            fi
        fi
    done

    # Show summary
    sdk_tester_show_summary

    echo ""
}

# Filter and run tests
sdk_tester_filter_and_run() {
    local pattern="$1"; shift
    sdk_tester_run_tests "$pattern" "$@"
}

# Clean test artifacts
sdk_tester_clean_artifacts() {
    local search_root="${D_CTX_DIR:-$(pwd)}"
    
    logit -i "Cleaning test artifacts..."
    
    # Remove common test artifacts
    find "$search_root" -name "*.test.log" -type f -delete 2>/dev/null || true
    find "$search_root" -name "*.test.tmp" -type f -delete 2>/dev/null || true
    find "$search_root" -name ".test_*" -type f -delete 2>/dev/null || true
    
    logit -o "Test artifacts cleaned"
}
