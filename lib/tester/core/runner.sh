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
    
    if [ "$TESTER_QUIET" != "true" ]; then
        logit -i "Running $(ansi 90 "$relative_path")"
    fi
    
    if [ "$TESTER_DRY_RUN" = "true" ]; then
        logit --ansi="$TESTER_COLOR_DIM" "  [DRY RUN] Would execute test file"
        return 0
    fi
    
    # Store current test counts to calculate file-specific results
    local file_start_total=$TESTER_TOTAL_TESTS
    local file_start_passed=$TESTER_PASSED_TESTS
    local file_start_failed=$TESTER_FAILED_TESTS
    local file_start_skipped=$TESTER_SKIPPED_TESTS
    
    # Source and execute the test file
    if [ -f "$test_file" ]; then
        # Source the test file in current shell to preserve test state
        source "$test_file"
        
        # Find and execute all test functions
        local test_functions
        test_functions=$(declare -F | grep "declare -f test_" | sed 's/declare -f //')
        
        if [ -z "$test_functions" ]; then
            logit -w "  No test functions found (functions should start with 'test_')"
            return 0
        fi
        
        if [ "$TESTER_VERBOSE" = "true" ]; then
            logit --ansi="$TESTER_COLOR_DIM" "  Found test functions: $(echo "$test_functions" | tr '\n' ' ')"
        fi
        
        # Run suite setup if defined
        if declare -f suite_setup >/dev/null 2>&1; then
            if [ "$TESTER_VERBOSE" = "true" ]; then
                logit --ansi="$TESTER_COLOR_DIM" "  Running suite setup..."
            fi
            if ! suite_setup; then
                logit -e "  Suite setup failed"
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
            
            if [ "$TESTER_VERBOSE" = "true" ]; then
                logit --ansi="90" "    → $test_function"
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
            
            # Check if we should fail fast
            if [ $test_exit_code -ne 0 ] && [ "$TESTER_FAIL_FAST" = "true" ]; then
                return 1
            fi
        done
        
        # Run suite teardown if defined (always run)
        if declare -f suite_teardown >/dev/null 2>&1; then
            if [ "$TESTER_VERBOSE" = "true" ]; then
                logit --ansi="$TESTER_COLOR_DIM" "  Running suite teardown..."
            fi
            suite_teardown
        fi
        
        local exit_code=$?
        if [ $exit_code -ne 0 ] && [ "$TESTER_FAIL_FAST" = "true" ]; then
            return $exit_code
        fi
    else
        logit -e "  Test file not found: $test_file"
        return 1
    fi
    
    # Calculate and display file-specific results
    local file_total=$((TESTER_TOTAL_TESTS - file_start_total))
    local file_passed=$((TESTER_PASSED_TESTS - file_start_passed))
    local file_failed=$((TESTER_FAILED_TESTS - file_start_failed))
    local file_skipped=$((TESTER_SKIPPED_TESTS - file_start_skipped))
    
    if [ "$TESTER_QUIET" != "true" ] && [ $file_total -gt 0 ]; then
        if [ $file_failed -gt 0 ]; then
            logit -f "$file_passed passed, $file_failed failed, $file_skipped skipped"
        else
            logit -o "$file_passed passed, $file_failed failed, $file_skipped skipped"
        fi
    fi
    
    return 0
}

# Main test runner function
sdk_tester_run_tests() {
    # Parse options and get remaining arguments
    local remaining_args
    remaining_args=($(_sdk_tester_parse_options "$@"))
    local pattern="${remaining_args[0]:-}"
    
    # Initialize test state
    sdk_tester_initialize
    TESTER_START_TIME=$(date +%s)
    
    if [ "$TESTER_VERBOSE" = "true" ]; then
        logit --ansi="$TESTER_COLOR_DIM" "Initialized counters: TOTAL=$TESTER_TOTAL_TESTS, PASSED=$TESTER_PASSED_TESTS, FAILED=$TESTER_FAILED_TESTS"
    fi
    
    # Show header
    if [ "$TESTER_QUIET" != "true" ]; then
        logit -i "DISEEC SDK TESTING FRAMEWORK"
        if [ -n "$pattern" ]; then
            logit -l "Filter: $pattern"
        fi
        echo ""
    fi
    
    # Get test files
    local test_files
    test_files=$(_sdk_tester_get_test_files "$pattern")
    
    if [ -z "$test_files" ]; then
        if [ -n "$pattern" ]; then
            logit -w "No test files found matching pattern: $pattern"
        else
            logit -w "No test files found. Create files ending with '.test.sh' to get started."
        fi
        return 1
    fi
    
    local test_count
    test_count=$(echo "$test_files" | wc -l | tr -d ' ')
    
    if [ "$TESTER_QUIET" != "true" ]; then
        logit -i "Discovered $test_count test file(s)"
        echo ""
    fi
    
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
