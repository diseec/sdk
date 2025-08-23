#!/bin/bash

# Basic connectivity tests for internet connectivity checker

# Quick connectivity test
quick_check() {
    local timeout=$QUICK_TIMEOUT
    local overall_status=true
    local start_time=$(date +%s.%N)
    
    # Detect ping command options based on OS
    local ping_cmd="ping"
    local ping_timeout_opt=""
    if ping -W 1 -c 1 127.0.0.1 >/dev/null 2>&1; then
        # Linux ping (supports -W for timeout)
        ping_timeout_opt="-W $timeout"
    elif ping -t $timeout -c 1 127.0.0.1 >/dev/null 2>&1; then
        # macOS ping (supports -t for timeout)
        ping_timeout_opt="-t $timeout"
    else
        # Fallback: no timeout option
        ping_timeout_opt=""
    fi
    
    # Test gateway
    get_gateway
    if [ -n "$LOCAL_GATEWAY" ]; then
        local test_start=$(date +%s.%N)
        if timeout ${timeout}s ping -c 1 $ping_timeout_opt "$LOCAL_GATEWAY" >/dev/null 2>&1 || \
           ping -c 1 $ping_timeout_opt "$LOCAL_GATEWAY" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "SUCCESS" "Gateway ping" "$LOCAL_GATEWAY" "${duration}s"
            GATEWAY_STATUS="SUCCESS"
        else
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "FAIL" "Gateway ping" "$LOCAL_GATEWAY (timeout after ${timeout}s)" "${duration}s"
            GATEWAY_STATUS="FAIL"
            overall_status=false
        fi
    else
        log_status "FAIL" "Gateway detection" "No default gateway found in routing table"
        GATEWAY_STATUS="FAIL"
        overall_status=false
    fi
    
    # Test DNS
    local test_start=$(date +%s.%N)
    if timeout ${timeout}s ping -c 1 $ping_timeout_opt "$QUICK_DNS" >/dev/null 2>&1 || \
       ping -c 1 $ping_timeout_opt "$QUICK_DNS" >/dev/null 2>&1; then
        local test_end=$(date +%s.%N)
        local duration=$(calculate_duration "$test_start" "$test_end")
        log_status "SUCCESS" "DNS server ping" "$QUICK_DNS" "${duration}s"
        DNS_PING_STATUS="SUCCESS"
    else
        local test_end=$(date +%s.%N)
        local duration=$(calculate_duration "$test_start" "$test_end")
        log_status "FAIL" "DNS server ping" "$QUICK_DNS (timeout after ${timeout}s)" "${duration}s"
        DNS_PING_STATUS="FAIL"
        overall_status=false
    fi
    
    # Test internet
    local test_start=$(date +%s.%N)
    # Use multiple attempts with different timeouts to be more reliable
    if curl -s --max-time $timeout --connect-timeout 2 -I "https://$QUICK_SITE" >/dev/null 2>&1 || \
       curl -s --max-time 5 --connect-timeout 3 "https://$QUICK_SITE" >/dev/null 2>&1; then
        local test_end=$(date +%s.%N)
        local duration=$(calculate_duration "$test_start" "$test_end")
        log_status "SUCCESS" "Internet HTTPS" "$QUICK_SITE" "${duration}s"
        INTERNATIONAL_HTTPS_COUNT=$((INTERNATIONAL_HTTPS_COUNT + 1))
    else
        # Try ping if HTTPS fails
        if timeout ${timeout}s ping -c 1 $ping_timeout_opt "$QUICK_SITE" >/dev/null 2>&1 || \
           ping -c 1 $ping_timeout_opt "$QUICK_SITE" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "FAIL" "Internet connectivity" "$QUICK_SITE - ping OK but HTTPS blocked/filtered" "${duration}s"
            INTERNATIONAL_PING_COUNT=$((INTERNATIONAL_PING_COUNT + 1))
            overall_status=false  # WARNING should also fail the overall test
        else
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "FAIL" "Internet connectivity" "$QUICK_SITE - both ping and HTTPS failed" "${duration}s"
            overall_status=false
        fi
    fi
    
    local end_time=$(date +%s.%N)
    local total_duration=$(calculate_duration "$start_time" "$end_time")
    if [ "$MODE" = "diagnose" ]; then
        echo "Quick check completed in ${total_duration}s"
    fi
    
    return $([[ "$overall_status" = true ]] && echo 0 || echo 1)
}
