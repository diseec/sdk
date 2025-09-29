#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST REPORTER                                                           ┃
# ┃ Elegant test result reporting with compact, trace-inspired styling      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Show minimal test header - clean and focused
sdk_tester_show_header() {
    local test_count="$1"
    local pattern="$2"
    
    # Don't show the "Found X test file(s)" line - too noisy
    return 0
}

# Show test execution summary
sdk_tester_show_summary() {
    if [ "$TESTER_QUIET" = "true" ] && [ $TESTER_FAILED_TESTS -eq 0 ]; then
        return 0
    fi
    
    local end_time=$(date +%s)
    local duration=$(_sdk_tester_format_duration $((end_time - TESTER_START_TIME)))
    
    # Compact results display - inspired by debug trace aesthetic
    printf "\033[1;97mRESULTS\033[0m\033[97m %s\033[0m\n" "$(printf '%*s' 67 | tr ' ' '-')"
    
    # Show "only" mode indicator if active
    if sdk_tester_registry_has_only; then
        printf "\033[33m⚠\033[0m \033[90mRunning in \033[97mONLY\033[0m\033[90m mode (other tests skipped)\033[0m\n"
    fi
    
    if [ $TESTER_TOTAL_TESTS -gt 0 ]; then
        # Single line with all key metrics, color-coded by status
        if [ $TESTER_FAILED_TESTS -eq 0 ]; then
            printf "\033[32m✓\033[0m \033[97m%d\033[0m\033[90m passed\033[0m" "$TESTER_PASSED_TESTS"
        else
            printf "\033[31m✖\033[0m \033[97m%d\033[0m\033[90m passed\033[0m \033[31m%d\033[0m\033[90m failed\033[0m" "$TESTER_PASSED_TESTS" "$TESTER_FAILED_TESTS"
        fi
        
        # Add skipped count if any
        if [ $TESTER_SKIPPED_TESTS -gt 0 ]; then
            printf " \033[33m%d\033[0m\033[90m skipped\033[0m" "$TESTER_SKIPPED_TESTS"
        fi
        
        # Success rate and duration on same line
        local success_rate=0
        if [ $TESTER_TOTAL_TESTS -gt 0 ]; then
            success_rate=$(( (TESTER_PASSED_TESTS * 100) / TESTER_TOTAL_TESTS ))
        fi
        
        # Get coverage statistics
        local coverage_stats
        coverage_stats=$(sdk_tester_calculate_coverage)
        local coverage_percent=$(echo "$coverage_stats" | cut -d':' -f1)
        local covered_files=$(echo "$coverage_stats" | cut -d':' -f2)
        local total_files=$(echo "$coverage_stats" | cut -d':' -f3)
        local orphaned_tests=$(echo "$coverage_stats" | cut -d':' -f4)
        
        printf " \033[90m|\033[0m \033[97m%d%%\033[0m\033[90m success\033[0m \033[90m|\033[0m \033[97m%s\033[0m \033[90m|\033[0m \033[97m%d%%\033[0m\033[90m coverage\033[0m \033[90m(%d/%d files" \
            "$success_rate" "$duration" "$coverage_percent" "$covered_files" "$total_files"
        
        if [ "$orphaned_tests" -gt 0 ]; then
            printf ", %d orphaned" "$orphaned_tests"
        fi
        printf ")\033[0m\n"
        
    else
        printf "\033[33m[!]\033[0m \033[90mNo tests executed\033[0m\n"
        return 1
    fi
    
    return 0
}

# Show detailed test progress (for verbose mode)
sdk_tester_show_progress() {
    local current_test="$1"
    local total_tests="$2"
    local test_name="$3"
    
    if [ "$TESTER_VERBOSE" = "true" ]; then
        local progress="[$current_test/$total_tests]"
        stdout --ansi="$TESTER_COLOR_DIM" "$(ansi 90 "$progress") $test_name"
    fi
}

# Show test file header - compact style with results in timestamp
sdk_tester_show_file_header() {
    local test_file="$1"
    local search_root="${D_CTX_DIR:-$(pwd)}"
    local relative_path="${test_file#$search_root/}"
    
    if [ "$TESTER_QUIET" != "true" ]; then
        # Extract directory and filename for different styling
        local dir_path="$(dirname "$relative_path")"
        local filename="$(basename "$relative_path")"
        
        local timestamp=$(date "+%H:%M:%S")
        
        # Show path in gray, filename in white (print as temp status)
        # This will be overwritten by the results
    fi
}

# Format elapsed time nicely
_sdk_tester_format_duration() {
    local seconds="$1"
    
    if [ $seconds -lt 60 ]; then
        echo "${seconds}s"
    elif [ $seconds -lt 3600 ]; then
        local minutes=$((seconds / 60))
        local secs=$((seconds % 60))
        echo "${minutes}m${secs}s"
    else
        local hours=$((seconds / 3600))
        local minutes=$(((seconds % 3600) / 60))
        local secs=$((seconds % 60))
        echo "${hours}h${minutes}m${secs}s"
    fi
}

# Show compact file test results - move counts to timestamp brackets
sdk_tester_show_file_results() {
    local file_passed="$1"
    local file_failed="$2" 
    local file_skipped="$3"
    local file_total="$4"

    if [ "$TESTER_QUIET" != "true" ] && [ $file_total -gt 0 ]; then
        local timestamp=$(date "+%H:%M:%S")
        local search_root="${D_CTX_DIR:-$(pwd)}"
        local relative_path="${TESTER_CURRENT_SUITE}"
        
        # Extract directory and filename for different styling
        local dir_path="$(dirname "$relative_path")"
        local filename="$(basename "$relative_path")"

        # Show timestamp with counts, then path with filename styled
        printf "\033[90m[%s][\033[90m%d\033[0m\033[2;90m/%d\033[0;90m]\033[0m " "$timestamp" "$file_passed" "$file_total"
        
        # Show path in gray, filename in white
        if [ "$dir_path" = "." ]; then
            printf "\033[97m%s\033[0m" "$filename"
        else
            printf "\033[90m%s/\033[0m\033[97m%s\033[0m" "$dir_path" "$filename"
        fi
        
        # Add success indicator at the end
        if [ $file_failed -gt 0 ]; then
            printf " \033[31m✖\033[0m"
        else
            printf " \033[32m✓\033[0m"
        fi
        
        # Show failure details if verbose mode
        if [ "$TESTER_VERBOSE" = "true" ] && [ $file_failed -gt 0 ]; then
            printf " \033[31m(%d failed)\033[0m" "$file_failed"
        fi
        if [ "$TESTER_VERBOSE" = "true" ] && [ $file_skipped -gt 0 ]; then
            printf " \033[33m(%d skipped)\033[0m" "$file_skipped"
        fi
        
        printf "\n"
    elif [ "$TESTER_QUIET" != "true" ]; then
        # First output a newline to ensure we're on a fresh line
        printf "\n"
        local timestamp=$(date "+%H:%M:%S")
        local relative_path="${TESTER_CURRENT_SUITE}"
        local dir_path="$(dirname "$relative_path")"
        local filename="$(basename "$relative_path")"
        
        printf "\033[90m[%s][0/0]\033[0m " "$timestamp"
        if [ "$dir_path" = "." ]; then
            printf "\033[97m%s\033[0m \033[33m[!]\033[0m" "$filename"
        else
            printf "\033[90m%s/\033[0m\033[97m%s\033[0m \033[33m[!]\033[0m" "$dir_path" "$filename"
        fi
    fi
}

# Show individual assertion result - compact with verbose expansion
sdk_tester_show_assertion_result() {
    local success="$1"
    local message="$2"
    local test_name="${3:-$TESTER_CURRENT_TEST}"
    
    if [ "$TESTER_VERBOSE" = "true" ]; then
        if [ "$success" = "true" ]; then
            printf " \033[32m·\033[0m"
        else
            printf "\n    \033[31m✖\033[0m \033[97m%s\033[0m" "$message"
        fi
    fi
}
