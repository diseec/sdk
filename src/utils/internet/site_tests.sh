#!/bin/bash

# Site connectivity tests for international, regional, and CDN testing

# Test international connectivity (diagnose mode only)
test_international_sites() {
    printf "${BLUE}International Connectivity${NC}\n"
    
    local international_working=false
    local timeout=$FULL_TIMEOUT
    
    # Detect ping command options
    local ping_timeout_opt=""
    if ping -W 1 -c 1 127.0.0.1 >/dev/null 2>&1; then
        ping_timeout_opt="-W 5"
    elif ping -t 5 -c 1 127.0.0.1 >/dev/null 2>&1; then
        ping_timeout_opt="-t 5"
    fi
    
    # Simple ping test function
    ping_test() {
        local target="$1"
        local timeout_sec="5"
        
        if ping -c 2 -W "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 2 -w "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 2 -t "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif command -v timeout >/dev/null 2>&1 && timeout "${timeout_sec}s" ping -c 2 "$target" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    }
    
    for site in "${INTERNATIONAL_SITES[@]}"; do
        # Use HEAD request first (faster), then fall back to GET if needed
        if curl -s --max-time $timeout --connect-timeout 5 -I "https://$site" >/dev/null 2>&1 || \
           curl -s --max-time $timeout --connect-timeout 5 "https://$site" >/dev/null 2>&1; then
            log_status "SUCCESS" "International site reachable" "$site (HTTPS)"
            INTERNATIONAL_HTTPS_COUNT=$((INTERNATIONAL_HTTPS_COUNT + 1))
            international_working=true
        else
            if ping_test "$site"; then
                log_status "WARNING" "Site pingable, HTTPS blocked" "$site"
                INTERNATIONAL_PING_COUNT=$((INTERNATIONAL_PING_COUNT + 1))
            else
                log_status "FAIL" "International site unreachable" "$site"
            fi
        fi
    done
    
    [ "$international_working" = true ]
}

# Test regional sites (diagnose mode only)
test_regional_sites() {
    printf "${BLUE}Regional Connectivity${NC}\n"

    local regional_working=false
    local timeout=$FULL_TIMEOUT
    
    # Detect ping command options
    local ping_timeout_opt=""
    if ping -W 1 -c 1 127.0.0.1 >/dev/null 2>&1; then
        ping_timeout_opt="-W 5"
    elif ping -t 5 -c 1 127.0.0.1 >/dev/null 2>&1; then
        ping_timeout_opt="-t 5"
    fi
    
    # Simple ping test function
    ping_test() {
        local target="$1"
        local timeout_sec="5"
        
        if ping -c 2 -W "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 2 -w "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif ping -c 2 -t "$timeout_sec" "$target" >/dev/null 2>&1; then
            return 0
        elif command -v timeout >/dev/null 2>&1 && timeout "${timeout_sec}s" ping -c 2 "$target" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    }
    
    for site in "${REGIONAL_SITES[@]}"; do
        if curl -s --max-time $timeout --connect-timeout 5 "https://$site" >/dev/null 2>&1; then
            log_status "SUCCESS" "Regional site reachable" "$site (HTTPS)"
            REGIONAL_HTTPS_COUNT=$((REGIONAL_HTTPS_COUNT + 1))
            regional_working=true
        else
            if ping_test "$site"; then
                log_status "WARNING" "Site pingable, HTTPS filtered" "$site"
                REGIONAL_PING_COUNT=$((REGIONAL_PING_COUNT + 1))
                regional_working=true
            else
                log_status "FAIL" "Regional site unreachable" "$site"
            fi
        fi
    done
    
    [ "$regional_working" = true ]
}

# Test CDN connectivity (diagnose mode only)
test_cdn_connectivity() {
    printf "${BLUE}CDN Connectivity${NC}\n"

    local cdn_working=false
    local timeout=$FULL_TIMEOUT
    
    for cdn in "${CDN_SITES[@]}"; do
        if curl -s --max-time $timeout --connect-timeout 5 "https://$cdn" >/dev/null 2>&1; then
            log_status "SUCCESS" "CDN reachable" "$cdn"
            CDN_HTTPS_COUNT=$((CDN_HTTPS_COUNT + 1))
            cdn_working=true
        else
            log_status "FAIL" "CDN unreachable" "$cdn"
        fi
    done
    
    [ "$cdn_working" = true ]
}
