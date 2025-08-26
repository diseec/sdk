#!/bin/bash

# DNS testing functions for internet connectivity checker

# Test DNS servers (diagnose mode only)
test_dns_servers() {
    printf "${BLUE}DNS Server Connectivity${NC}\n"

    local dns_working=false
    local timeout=$FULL_TIMEOUT
    local dns_success_count=0
    
    # Detect ping command options based on OS
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
    
    # Simple ping test function
    ping_test() {
        local target="$1"
        local timeout_sec="$2"
        
        if ping -c 2 -W "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 2 -w "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 2 -t "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif command -v timeout >/dev/null 2>&1 && timeout "$((timeout_sec * 2))s" ping -c 2 "$target" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    }
    
    for dns in "${DNS_SERVERS[@]}"; do
        if ping_test "$dns" "$timeout"; then
            log_status "SUCCESS" "DNS server reachable" "$dns"
            dns_working=true
            dns_success_count=$((dns_success_count + 1))
        else
            log_status "FAIL" "DNS server unreachable" "$dns"
        fi
    done
    
    # Test DNS resolution using multiple methods
    local dns_resolution_working=false
    
    # Method 1: Use nslookup if available
    if command -v nslookup >/dev/null 2>&1 && nslookup google.com >/dev/null 2>&1; then
        dns_resolution_working=true
    # Method 2: Use dig if available  
    elif command -v dig >/dev/null 2>&1 && dig google.com >/dev/null 2>&1; then
        dns_resolution_working=true
    # Method 3: Use host if available
    elif command -v host >/dev/null 2>&1 && host google.com >/dev/null 2>&1; then
        dns_resolution_working=true
    # Method 4: Try resolving via /etc/hosts or system resolver
    elif command -v getent >/dev/null 2>&1 && getent hosts google.com >/dev/null 2>&1; then
        dns_resolution_working=true
    # Method 5: Use ping as a resolution test (if it fails with unknown host, DNS is broken)
    elif ping -c 1 google.com >/dev/null 2>&1; then
        dns_resolution_working=true
    fi
    
    if [ "$dns_resolution_working" = "true" ]; then
        log_status "SUCCESS" "DNS resolution working"
        DNS_RESOLUTION_STATUS="SUCCESS"
        dns_working=true
    else
        log_status "FAIL" "DNS resolution failed"
        DNS_RESOLUTION_STATUS="FAIL"
    fi
    
    # Set overall DNS status based on results
    if [ "$dns_success_count" -gt 0 ] && [ "$DNS_RESOLUTION_STATUS" = "SUCCESS" ]; then
        DNS_PING_STATUS="SUCCESS"
    else
        DNS_PING_STATUS="FAIL"
    fi
    
    [ "$dns_working" = true ]
}
