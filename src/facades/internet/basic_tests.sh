#!/bin/bash

# Basic connectivity tests for internet connectivity checker

# Quick connectivity test
fac_int_quick_check() {
    local timeout=$QUICK_TIMEOUT
    local overall_status=true
    local start_time=$(date +%s.%N)
    
    # Simple ping test function that works on all systems
    ping_test() {
        local target="$1"
        local timeout_sec="$2"
        
        # Try different ping syntaxes to find what works
        if ping -c 1 -W "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 1 -w "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 1 -t "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif command -v timeout >/dev/null 2>&1 && timeout "${timeout_sec}s" ping -c 1 "$target" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    }
    
    # Test gateway
    fac_int_get_gateway
    if [ -n "$LOCAL_GATEWAY" ]; then
        local test_start=$(date +%s.%N)
        if ping_test "$LOCAL_GATEWAY" "$timeout"; then
            local test_end=$(date +%s.%N)
            local duration=$(fac_int_calculate_duration "$test_start" "$test_end")
            fac_int_log_status "SUCCESS" "Gateway ping" "$LOCAL_GATEWAY" "${duration}s"
            GATEWAY_STATUS="SUCCESS"
        else
            local test_end=$(date +%s.%N)
            local duration=$(fac_int_calculate_duration "$test_start" "$test_end")
            fac_int_log_status "FAIL" "Gateway ping" "$LOCAL_GATEWAY (timeout after ${timeout}s)" "${duration}s"
            GATEWAY_STATUS="FAIL"
            overall_status=false
        fi
    else
        fac_int_log_status "FAIL" "Gateway detection" "No default gateway found in routing table"
        GATEWAY_STATUS="FAIL"
        overall_status=false
    fi
    
    # Test DNS
    local test_start=$(date +%s.%N)
    if ping_test "$QUICK_DNS" "$timeout"; then
        local test_end=$(date +%s.%N)
        local duration=$(fac_int_calculate_duration "$test_start" "$test_end")
        fac_int_log_status "SUCCESS" "DNS server ping" "$QUICK_DNS" "${duration}s"
        DNS_PING_STATUS="SUCCESS"
    else
        local test_end=$(date +%s.%N)
        local duration=$(fac_int_calculate_duration "$test_start" "$test_end")
        fac_int_log_status "FAIL" "DNS server ping" "$QUICK_DNS (timeout after ${timeout}s)" "${duration}s"
        DNS_PING_STATUS="FAIL"
        overall_status=false
    fi
    
    # Test internet
    local test_start=$(date +%s.%N)
    # Use multiple attempts with different timeouts to be more reliable
    if curl -s --max-time $timeout --connect-timeout 2 -I "https://$QUICK_SITE" >/dev/null 2>&1 || \
       curl -s --max-time 5 --connect-timeout 3 "https://$QUICK_SITE" >/dev/null 2>&1; then
        local test_end=$(date +%s.%N)
        local duration=$(fac_int_calculate_duration "$test_start" "$test_end")
        fac_int_log_status "SUCCESS" "Internet HTTPS" "$QUICK_SITE" "${duration}s"
        INTERNATIONAL_HTTPS_COUNT=$((INTERNATIONAL_HTTPS_COUNT + 1))
    else
        # Try ping if HTTPS fails
        if ping_test "$QUICK_SITE" "$timeout"; then
            local test_end=$(date +%s.%N)
            local duration=$(fac_int_calculate_duration "$test_start" "$test_end")
            fac_int_log_status "FAIL" "Internet connectivity" "$QUICK_SITE - ping OK but HTTPS blocked/filtered" "${duration}s"
            INTERNATIONAL_PING_COUNT=$((INTERNATIONAL_PING_COUNT + 1))
            overall_status=false  # WARNING should also fail the overall test
        else
            local test_end=$(date +%s.%N)
            local duration=$(fac_int_calculate_duration "$test_start" "$test_end")
            fac_int_log_status "FAIL" "Internet connectivity" "$QUICK_SITE - both ping and HTTPS failed" "${duration}s"
            overall_status=false
        fi
    fi
    
    local end_time=$(date +%s.%N)
    local total_duration=$(fac_int_calculate_duration "$start_time" "$end_time")
    if [ "$MODE" = "diagnose" ]; then
        echo "Quick check completed in ${total_duration}s"
    fi
    
    return $([[ "$overall_status" = true ]] && echo 0 || echo 1)
}
