#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST REPORTER                                                           ┃
# ┃ Beautiful test result reporting with statistics and summaries           ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Show test execution summary
sdk_tester_show_summary() {
    if [ "$TESTER_QUIET" = "true" ] && [ $TESTER_FAILED_TESTS -eq 0 ]; then
        return 0
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - TESTER_START_TIME))
    
    echo ""
    logit -i "TEST RESULTS SUMMARY"
    echo ""
    
    # Show counts using SDK styling
    if [ $TESTER_TOTAL_TESTS -gt 0 ]; then
        logit -l "Passed:   $TESTER_PASSED_TESTS"
        logit -l "Failed:   $TESTER_FAILED_TESTS" 
        logit -l "Skipped:  $TESTER_SKIPPED_TESTS"
        logit -l "Total:    $TESTER_TOTAL_TESTS"
        echo ""
        
        # Calculate success rate
        local success_rate=0
        if [ $TESTER_TOTAL_TESTS -gt 0 ]; then
            success_rate=$(( (TESTER_PASSED_TESTS * 100) / TESTER_TOTAL_TESTS ))
        fi
        
        logit -l "Success Rate: ${success_rate}%"
        logit -l "Duration:     ${duration}s"
    else
        logit -w "No tests were executed"
    fi
    
    echo ""
    
    # Final status message
    if [ $TESTER_FAILED_TESTS -eq 0 ]; then
        if [ $TESTER_TOTAL_TESTS -gt 0 ]; then
            logit -o "All tests passed!"
        fi
        return 0
    else
        logit -f "Some tests failed. Fix them and try again."
        return 1
    fi
}

# Show detailed test progress (for verbose mode)
sdk_tester_show_progress() {
    local current_test="$1"
    local total_tests="$2"
    local test_name="$3"
    
    if [ "$TESTER_VERBOSE" = "true" ]; then
        local progress="[$current_test/$total_tests]"
        logit --ansi="$TESTER_COLOR_DIM" "$(ansi 90 "$progress") $test_name"
    fi
}

# Show test file header
sdk_tester_show_file_header() {
    local test_file="$1"
    local search_root="${D_CTX_DIR:-$(pwd)}"
    local relative_path="${test_file#$search_root/}"
    
    if [ "$TESTER_QUIET" != "true" ]; then
        echo ""
        logit --ansi="$TESTER_COLOR_SUITE" "$(ansi $TESTER_COLOR_SUITE "▶") Testing $(ansi 97 "$relative_path")"
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
        echo "${minutes}m ${secs}s"
    else
        local hours=$((seconds / 3600))
        local minutes=$(((seconds % 3600) / 60))
        local secs=$((seconds % 60))
        echo "${hours}h ${minutes}m ${secs}s"
    fi
}

# Show individual assertion result (for verbose mode)
sdk_tester_show_assertion_result() {
    local success="$1"
    local message="$2"
    local test_name="${3:-$TESTER_CURRENT_TEST}"
    
    if [ "$TESTER_VERBOSE" = "true" ]; then
        if [ "$success" = "true" ]; then
            logit --ansi="$TESTER_COLOR_DIM" "      $(ansi $TESTER_COLOR_PASS "✓") $message"
        else
            logit --ansi="$TESTER_COLOR_FAIL" "      $(ansi $TESTER_COLOR_FAIL "✖") $message"
        fi
    fi
}
