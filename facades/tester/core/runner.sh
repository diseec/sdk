#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST RUNNER ENGINE                                                      ┃
# ┃ Executes test files and manages test execution lifecycle                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Get test functions in the order they appear in the file, respecting "only" functionality
_sdk_tester_get_functions_in_order() {
    local test_file="$1"
    
    if [ ! -f "$test_file" ]; then
        return 1
    fi
    
    # Parse the file to find function definitions in order
    local all_functions
    all_functions=$(grep -n "^[[:space:]]*test_[a-zA-Z0-9_]*[[:space:]]*(" "$test_file" | sed 's/^[0-9]*:[[:space:]]*\(test_[a-zA-Z0-9_]*\)[[:space:]]*(.*/\1/')
    
    if [ -z "$all_functions" ]; then
        return 1
    fi
    
    # Check if any functions have the "_only" suffix
    local only_functions
    only_functions=$(echo "$all_functions" | grep "_only$")
    
    if [ -n "$only_functions" ]; then
        # If there are "only" functions, return only those
        echo "$only_functions"
        # Set global flag for reporter (don't reset, accumulate)
        export TESTER_HAS_ONLY_FUNCTIONS=true
        echo "true" > "$TESTER_ONLY_FLAG_FILE" 2>/dev/null || true
    else
        # Return all functions in order
        echo "$all_functions"
        # Don't reset the flag, let it accumulate from other files
    fi
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
        printf "\033[90m(dry run)\033[0m"
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
        
        # Get test functions in file order, not alphabetical order
        local test_functions
        test_functions=$(_sdk_tester_get_functions_in_order "$test_file")
        
        if [ -z "$test_functions" ]; then
            # Fall back to the old alphabetical method if parsing fails
            test_functions=$(declare -F | grep "declare -f test_" | sed 's/declare -f //')
            
            if [ -z "$test_functions" ]; then
                printf "\033[33m[!]\033[0m \033[90mno test functions\033[0m\n"
                return 0
            fi
        fi
        
        # Run suite setup if defined
        if declare -f suite_setup >/dev/null 2>&1; then
            if ! suite_setup; then
                printf "\033[31m✖\033[0m \033[90msetup failed\033[0m\n"
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

        if [ "$TESTER_VERBOSE" = "true" ]; then
            echo ""
        fi

        # Now execute each test function in current shell
        for test_function in "${test_functions_array[@]}"; do
            TESTER_CURRENT_TEST="$test_function"
            
            # Show test function start in verbose mode
            if [ "$TESTER_VERBOSE" = "true" ]; then
                printf "  \033[2;90m→\033[0m \033[90m%s\033[0m" "$test_function"
            fi
            
            setup_test_ctx

            set +e

            # Run test setup if defined
            if declare -f setup_test >/dev/null 2>&1; then
                setup_test
            fi

            # Execute the test function
            "$test_function"
            local cmd_exit_code=$?
            
            # Check the test result file to determine actual test status
            # even if the command exit code is 0 (passed), the test might have failed assertions
            local test_exit_code=$cmd_exit_code
            if [ -f "$TESTER_RESULT_FILE" ]; then
                if grep -q "$TESTER_FAILURE_KEY" "$TESTER_RESULT_FILE"; then
                    # At least one assertion failed during the test
                    test_exit_code=1
                fi
            fi
            
            # If the test failed, display the logs
            if [ $test_exit_code -ne 0 ]; then
                local timestamp=$(date "+%H:%M:%S")
                printf "\n\n\033[1;97mCAPTURES\033[0m\033[97m %s\033[0m\n" "$(printf '%*s' 67 | tr ' ' '-')"
                
                # Display the captured logs from the file
                if [ -f "$TESTER_LOG_FILE" ] && [ -s "$TESTER_LOG_FILE" ]; then
                    # Strip ANSI color codes when displaying logs
                    cat "$TESTER_LOG_FILE"
                else
                    printf "\033[33m[!]\033[0m \033[90mNo command logs captured\033[0m\n"
                fi
            fi
            
            # Run test teardown if defined
            if declare -f teardown_test >/dev/null 2>&1; then
                teardown_test
            fi

            teardown_test_ctx

            set -e

            # Clean up test workspace and result file
            if [ -f "$TESTER_RESULT_FILE" ]; then
                rm -f "$TESTER_RESULT_FILE"
            fi
            cleanup_test_ctx "$TEST_CTX"
            
            # Show test function completion in verbose mode
            if [ "$TESTER_VERBOSE" = "true" ]; then
                echo ""
            fi
            
            # Check if we should fail fast
            if [ $test_exit_code -ne 0 ] && [ "$TESTER_FAIL_FAST" = "true" ]; then
                printf "\033[33m[!]\033[0m \033[90mFail-fast mode enabled, stopping\033[0m\n"
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
        
        # Also unset setup_test and teardown_test functions
        if declare -f setup_test >/dev/null 2>&1; then
            unset -f setup_test 2>/dev/null || true
        fi
        
        if declare -f teardown_test >/dev/null 2>&1; then
            unset -f teardown_test 2>/dev/null || true
        fi
        
        local exit_code=$?
        if [ $exit_code -ne 0 ] && [ "$TESTER_FAIL_FAST" = "true" ]; then
            return $exit_code
        fi
    else
        printf "\033[31m✖\033[0m \033[90mnot found\033[0m\n"
        return 1
    fi
    
    # Calculate and display file-specific results compactly
    local file_total=$((TESTER_TOTAL_TESTS - file_start_total))
    local file_passed=$((TESTER_PASSED_TESTS - file_start_passed))
    local file_failed=$((TESTER_FAILED_TESTS - file_start_failed))
    local file_skipped=$((TESTER_SKIPPED_TESTS - file_start_skipped))
    
    # Show compact results on same line as file header
    sdk_tester_show_file_results "$file_passed" "$file_failed" "$file_skipped" "$file_total"
    
    return 0
}

# Main test runner function
sdk_tester_run_tests() {

    # Initialize test state
    sdk_tester_initialize
    TESTER_START_TIME=$(date +%s)
    
    # Initialize the "only" flag globally
    export TESTER_HAS_ONLY_FUNCTIONS=false
    export TESTER_ONLY_FLAG_FILE="/tmp/tester_only_$$"
    echo "false" > "$TESTER_ONLY_FLAG_FILE"
    
    # Get test files
    local test_files
    test_files=$(_sdk_tester_get_test_files "$@")
    
    if [ -z "$test_files" ]; then
        local timestamp=$(date "+%H:%M:%S")
        if [ -n "$@" ]; then
            printf "\033[90m[%s]\033[0m\033[33m[!]\033[0m \033[90mNo tests match pattern:\033[0m \033[97m%s\033[0m\n" "$timestamp" "$@"
        else
            printf "\033[90m[%s]\033[0m\033[33m[!]\033[0m \033[90mNo test files found. Create\033[0m \033[97m*.test.sh\033[0m \033[90mfiles to start\033[0m\n" "$timestamp"
        fi
        return 1
    fi
    
    local test_count
    test_count=$(echo "$test_files" | wc -l | tr -d ' ')
    
    # Show compact header
    sdk_tester_show_header "$test_count" "$@"
    
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

    echo ""
    
    # Show summary
    sdk_tester_show_summary

    # Clean up temp files
    if [ -n "$TESTER_ONLY_FLAG_FILE" ] && [ -f "$TESTER_ONLY_FLAG_FILE" ]; then
        rm -f "$TESTER_ONLY_FLAG_FILE"
    fi

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
    
    stdout -i "Cleaning test artifacts..."
    
    # Remove common test artifacts
    find "$search_root" -name "*.test.log" -type f -delete 2>/dev/null || true
    find "$search_root" -name "*.test.tmp" -type f -delete 2>/dev/null || true
    find "$search_root" -name ".test_*" -type f -delete 2>/dev/null || true
    
    stdout -o "Test artifacts cleaned"
}
