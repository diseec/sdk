#!/bin/bash

# Configuration
QUICK_TIMEOUT=1
FULL_TIMEOUT=1

# Colors for status only
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Global variables to track test results for diagnosis
GATEWAY_STATUS=""
DNS_PING_STATUS=""
DNS_RESOLUTION_STATUS=""
INTERNATIONAL_HTTPS_COUNT=0
INTERNATIONAL_PING_COUNT=0
REGIONAL_HTTPS_COUNT=0
REGIONAL_PING_COUNT=0
CDN_HTTPS_COUNT=0
VPN_ONLY_CONNECTION=false
PRIMARY_CONNECTION_STATUS=""

# Test targets
LOCAL_GATEWAY=""
QUICK_DNS="8.8.8.8"
QUICK_SITE="diseec.com"
# DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9")
# INTERNATIONAL_SITES=("cloudflare.com" "github.com" "hub.docker.com" "diseec.com")
# REGIONAL_SITES=("aparat.com" "digikala.com" "khamenei.ir")
# CDN_SITES=("cdn.jsdelivr.net" "cdnjs.cloudflare.com")
DNS_SERVERS=("8.8.8.8")
INTERNATIONAL_SITES=("github.com" "hub.docker.com")
REGIONAL_SITES=("aparat.com" "khamenei.ir")
CDN_SITES=("cdnjs.cloudflare.com")

# Mode detection
MODE="test"
SILENT_MODE=false

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            dia|--diagnose|diagnose)
                MODE="diagnose"
                shift
                ;;
            tes|--test|test)
                MODE="test"
                shift
                ;;
            iso|--is-online|is-online)
                MODE="is-online"
                SILENT_MODE=true
                shift
                ;;
            --silent|silent)
                SILENT_MODE=true
                shift
                ;;
            --help|help|-h)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

show_help() {
    echo "Internet Connection Checker with Advanced Diagnostics"
    echo "===================================================="
    echo ""
    echo "Usage: $0 [mode] [options]"
    echo ""
    echo "Modes:"
    echo "  dia|diagnose    - Comprehensive analysis - tests all layers, sites, velocity, and disconnections (~45 seconds)"
    echo "  iso|is-online   - Silent boolean check - returns 0 for success, 1 for failure (no output)"
    echo "  tes|test        - Fast check with output - tests gateway, DNS, and one site (~3 seconds)"
    echo ""
    echo "Advanced Features (diagnose mode):"
    echo "  • Velocity analysis - measures request/response speed with variance detection"
    echo "  • Random disconnection testing - detects intermittent connection drops"
    echo "  • Speed consistency analysis - identifies throttling and congestion patterns"
    echo "  • Multi-round throughput testing - comprehensive bandwidth measurement"
    echo "  • Connection quality scoring - combines speed, stability, and consistency metrics"
    echo ""
    echo "Options:"
    echo "  --silent - Suppress all output except errors"
    echo "  --help  - Show this help message"
}

log_status() {
    local status=$1
    local test_name=$2
    local details=$3
    local timing=$4

    # In is-online mode, be completely silent - no output at all
    if [ "$MODE" = "is-online" ]; then
        return
    fi
    
    # In silent mode, only show failures and warnings
    if [ "$SILENT_MODE" = "true" ] && [ "$status" = "SUCCESS" ]; then
        return
    fi
    
    # Format output with timestamp and detailed info
    local timestamp=$(date '+%H:%M:%S')
        if [ "$status" = "SUCCESS" ]; then
        if [ "$MODE" = "diagnose" ] || [ "$MODE" = "test" ]; then
            printf "[%s]${NC}[PASS]${NC} %s" "$timestamp" "$test_name"
            [ -n "$details" ] && printf " - %s" "$details"
            [ -n "$timing" ] && printf " (took %s)" "$timing"
            printf "\n"
        fi
    elif [ "$status" = "WARNING" ]; then
        printf "[%s]${YELLOW}[WARN]${NC} %s" "$timestamp" "$test_name"
        [ -n "$details" ] && printf " - %s" "$details"
        [ -n "$timing" ] && printf " (took %s)" "$timing"
        printf "\n"
    else
        printf "[%s]${RED}[FAIL]${NC} %s" "$timestamp" "$test_name"
        [ -n "$details" ] && printf " - %s" "$details"
        [ -n "$timing" ] && printf " (took %s)" "$timing"
        printf "\n"
    fi
}

# Get default gateway
get_gateway() {
    LOCAL_GATEWAY=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}' | head -1)
    if [ -z "$LOCAL_GATEWAY" ]; then
        LOCAL_GATEWAY=$(netstat -rn | grep default | awk '{print $2}' | head -1)
    fi
}

# Quick connectivity test
quick_check() {
    local timeout=$QUICK_TIMEOUT
    local overall_status=true
    local start_time=$(date +%s.%N)
    
    # Test gateway
    get_gateway
    if [ -n "$LOCAL_GATEWAY" ]; then
        local test_start=$(date +%s.%N)
        if ping -c 1 -W $timeout "$LOCAL_GATEWAY" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "")
            log_status "SUCCESS" "Gateway ping" "$LOCAL_GATEWAY" "${duration}s"
            GATEWAY_STATUS="SUCCESS"
        else
            local test_end=$(date +%s.%N)
            local duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "")
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
    if ping -c 1 -W $timeout "$QUICK_DNS" >/dev/null 2>&1; then
        local test_end=$(date +%s.%N)
        local duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "")
        log_status "SUCCESS" "DNS server ping" "$QUICK_DNS" "${duration}s"
        DNS_PING_STATUS="SUCCESS"
    else
        local test_end=$(date +%s.%N)
        local duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "")
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
        local duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "")
        log_status "SUCCESS" "Internet HTTPS" "$QUICK_SITE" "${duration}s"
        INTERNATIONAL_HTTPS_COUNT=$((INTERNATIONAL_HTTPS_COUNT + 1))
    else
        # Try ping if HTTPS fails
        if ping -c 1 -W $timeout "$QUICK_SITE" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "")
            log_status "FAIL" "Internet connectivity" "$QUICK_SITE - ping OK but HTTPS blocked/filtered" "${duration}s"
            INTERNATIONAL_PING_COUNT=$((INTERNATIONAL_PING_COUNT + 1))
            overall_status=false  # WARNING should also fail the overall test
        else
            local test_end=$(date +%s.%N)
            local duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "")
            log_status "FAIL" "Internet connectivity" "$QUICK_SITE - both ping and HTTPS failed" "${duration}s"
            overall_status=false
        fi
    fi
    
    local end_time=$(date +%s.%N)
    local total_duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "")
    if [ "$MODE" = "diagnose" ]; then
        echo "Quick check completed in ${total_duration}s"
    fi
    
    return $([[ "$overall_status" = true ]] && echo 0 || echo 1)
}

# Test network interface
test_network_interface() {
    if [ "$MODE" != "test" ]; then
        printf "${BLUE}Network Interface Status${NC}\n"
    fi
    
    # Check for WiFi interfaces specifically
    local wifi_interfaces=$(ifconfig | grep -E "^(en[0-9]+|wl[0-9]+)" | grep -E "flags=.*<UP,.*RUNNING" | cut -d: -f1)
    local ethernet_interfaces=$(ifconfig | grep -E "^(en[0-9]+)" | grep -E "flags=.*<UP,.*RUNNING" | cut -d: -f1)
    local vpn_interfaces=$(ifconfig | grep -E "^(utun|tun|ppp)" | grep -E "flags=.*<UP,.*RUNNING" | cut -d: -f1)
    
    local primary_connection_found=false
    
    # Check WiFi/Ethernet first (primary connections)
    if [ -n "$wifi_interfaces" ] || [ -n "$ethernet_interfaces" ]; then
        for interface in $wifi_interfaces $ethernet_interfaces; do
            local ip=$(ifconfig "$interface" | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
            local status=$(ifconfig "$interface" | grep "status:" | awk '{print $2}' | head -1)
            if [ -n "$ip" ]; then
                local interface_type="Ethernet"
                if echo "$interface" | grep -q "en[0-9]"; then
                    # Check if this en interface is WiFi by looking for WiFi-specific info
                    if ifconfig "$interface" | grep -q "SSID\|AirPort"; then
                        interface_type="WiFi"
                    fi
                fi
                log_status "SUCCESS" "$interface_type interface $interface" "IP: $ip, Status: ${status:-active}"
                primary_connection_found=true
            fi
        done
    fi
    
    # Check VPN/Tunnel interfaces (secondary connections)
    if [ -n "$vpn_interfaces" ]; then
        for interface in $vpn_interfaces; do
            local ip=$(ifconfig "$interface" | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
            if [ -n "$ip" ]; then
                if [ "$primary_connection_found" = "true" ]; then
                    log_status "SUCCESS" "VPN/Tunnel interface $interface" "IP: $ip"
                else
                    log_status "WARNING" "VPN/Tunnel interface $interface" "IP: $ip (primary connection may be down)"
                fi
            fi
        done
    fi
    
    # If no primary connection but VPN exists, it's a warning situation
    if [ "$primary_connection_found" = "false" ] && [ -n "$vpn_interfaces" ]; then
        log_status "WARNING" "Network connectivity" "Only VPN/tunnel connections active, primary WiFi/Ethernet may be down"
        VPN_ONLY_CONNECTION=true
        PRIMARY_CONNECTION_STATUS="VPN_ONLY"
        return 1
    fi
    
    # If no connections at all
    if [ "$primary_connection_found" = "false" ] && [ -z "$vpn_interfaces" ]; then
        log_status "FAIL" "Network interfaces" "No active network interfaces with IP addresses found"
        PRIMARY_CONNECTION_STATUS="NO_CONNECTION"
        return 1
    fi
    
    PRIMARY_CONNECTION_STATUS="SUCCESS"
    return 0
}

# Test DNS servers (diagnose mode only)
test_dns_servers() {
    printf "${BLUE}DNS Server Connectivity${NC}\n"

    local dns_working=false
    local timeout=$FULL_TIMEOUT
    local dns_success_count=0
    
    for dns in "${DNS_SERVERS[@]}"; do
        if ping -c 2 -W $timeout "$dns" >/dev/null 2>&1; then
            log_status "SUCCESS" "DNS server reachable" "$dns"
            dns_working=true
            dns_success_count=$((dns_success_count + 1))
        else
            log_status "FAIL" "DNS server unreachable" "$dns"
        fi
    done
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
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

# Test international connectivity (diagnose mode only)
test_international_sites() {
    printf "${BLUE}International Connectivity${NC}\n"
    
    local international_working=false
    local timeout=$FULL_TIMEOUT
    
    for site in "${INTERNATIONAL_SITES[@]}"; do
        # Use HEAD request first (faster), then fall back to GET if needed
        if curl -s --max-time $timeout --connect-timeout 5 -I "https://$site" >/dev/null 2>&1 || \
           curl -s --max-time $timeout --connect-timeout 5 "https://$site" >/dev/null 2>&1; then
            log_status "SUCCESS" "International site reachable" "$site (HTTPS)"
            INTERNATIONAL_HTTPS_COUNT=$((INTERNATIONAL_HTTPS_COUNT + 1))
            international_working=true
        else
            if ping -c 2 -W 5 "$site" >/dev/null 2>&1; then
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
    
    for site in "${REGIONAL_SITES[@]}"; do
        if curl -s --max-time $timeout --connect-timeout 5 "https://$site" >/dev/null 2>&1; then
            log_status "SUCCESS" "Regional site reachable" "$site (HTTPS)"
            REGIONAL_HTTPS_COUNT=$((REGIONAL_HTTPS_COUNT + 1))
            regional_working=true
        else
            if ping -c 2 -W 5 "$site" >/dev/null 2>&1; then
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

# Test connection quality and speed
test_connection_quality() {
    printf "${BLUE}Connection Quality & Speed${NC}\n"

    # Extended latency tests with stability analysis
    local stability_issues=false
    
    if [ -n "$LOCAL_GATEWAY" ]; then
        printf "${BLUE}Testing gateway stability...${NC}\n"
        local gateway_stats=$(ping -c 10 "$LOCAL_GATEWAY" 2>/dev/null)
        local gateway_avg=$(echo "$gateway_stats" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
        local gateway_loss=$(echo "$gateway_stats" | grep "packet loss" | awk '{print $6}' | sed 's/%//' 2>/dev/null)
        
        if [ -n "$gateway_avg" ]; then
            log_status "SUCCESS" "Gateway average latency" "${gateway_avg}ms"
            if [ -n "$gateway_loss" ] && [ "$(echo "$gateway_loss > 0" | bc 2>/dev/null)" = "1" ]; then
                log_status "WARNING" "Gateway packet loss" "${gateway_loss}%"
                stability_issues=true
            fi
        fi
    fi
    
    # DNS stability test
    printf "${BLUE}Testing DNS stability...${NC}\n"
    local dns_stats=$(ping -c 10 8.8.8.8 2>/dev/null)
    local dns_avg=$(echo "$dns_stats" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
    local dns_loss=$(echo "$dns_stats" | grep "packet loss" | awk '{print $6}' | sed 's/%//' 2>/dev/null)
    
    if [ -n "$dns_avg" ]; then
        log_status "SUCCESS" "DNS average latency" "${dns_avg}ms"
        if [ -n "$dns_loss" ] && [ "$(echo "$dns_loss > 0" | bc 2>/dev/null)" = "1" ]; then
            log_status "WARNING" "DNS packet loss" "${dns_loss}%"
            stability_issues=true
        fi
    fi
    
    # International connectivity stability
    printf "${BLUE}Testing international stability...${NC}\n"
    local intl_stats=$(ping -c 10 google.com 2>/dev/null)
    local intl_avg=$(echo "$intl_stats" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
    local intl_loss=$(echo "$intl_stats" | grep "packet loss" | awk '{print $6}' | sed 's/%//' 2>/dev/null)
    
    if [ -n "$intl_avg" ]; then
        log_status "SUCCESS" "International average latency" "${intl_avg}ms"
        if [ -n "$intl_loss" ] && [ "$(echo "$intl_loss > 0" | bc 2>/dev/null)" = "1" ]; then
            log_status "WARNING" "International packet loss" "${intl_loss}%"
            stability_issues=true
        fi
    fi
    
    # Random disconnection test
    printf "${BLUE}Testing for random disconnections...${NC}\n"
    local disconnection_count=0
    local velocity_variance=0
    local test_rounds=5
    local velocities=()
    
    for i in $(seq 1 $test_rounds); do
        printf "Round $i/$test_rounds... "
        local round_start=$(date +%s.%N)
        
        # Quick connectivity burst test
        local quick_test_success=0
        local quick_tests=3
        
        for j in $(seq 1 $quick_tests); do
            if curl -s --max-time 2 --connect-timeout 1 -I "https://diseec.com" >/dev/null 2>&1; then
                quick_test_success=$((quick_test_success + 1))
            else
                disconnection_count=$((disconnection_count + 1))
            fi
            sleep 0.5  # Small delay between tests
        done
        
        local round_end=$(date +%s.%N)
        local round_duration=$(echo "$round_end - $round_start" | bc 2>/dev/null || echo "1")
        local round_velocity=$(echo "scale=2; $quick_test_success / $round_duration" | bc 2>/dev/null || echo "0")
        velocities+=("$round_velocity")
        
        printf "Success: $quick_test_success/$quick_tests, Velocity: ${round_velocity} req/sec\n"
        sleep 1  # Rest between rounds
    done
    
    # Calculate velocity statistics
    local total_velocity=0
    local velocity_count=${#velocities[@]}
    for vel in "${velocities[@]}"; do
        total_velocity=$(echo "$total_velocity + $vel" | bc 2>/dev/null || echo "$total_velocity")
    done
    
    local avg_velocity=$(echo "scale=2; $total_velocity / $velocity_count" | bc 2>/dev/null || echo "0")
    
    # Calculate velocity variance for consistency analysis
    local variance_sum=0
    for vel in "${velocities[@]}"; do
        local diff=$(echo "$vel - $avg_velocity" | bc 2>/dev/null || echo "0")
        local diff_squared=$(echo "$diff * $diff" | bc 2>/dev/null || echo "0")
        variance_sum=$(echo "$variance_sum + $diff_squared" | bc 2>/dev/null || echo "$variance_sum")
    done
    local velocity_variance=$(echo "scale=2; $variance_sum / $velocity_count" | bc 2>/dev/null || echo "0")
    
    # Report disconnection analysis
    local total_tests=$((test_rounds * quick_tests))
    local success_rate=$((total_tests - disconnection_count))
    local disconnection_percentage=$(echo "scale=2; ($disconnection_count * 100) / $total_tests" | bc 2>/dev/null || echo "0")
    
    if [ "$disconnection_count" -eq 0 ]; then
        log_status "SUCCESS" "Connection stability" "No disconnections detected in $total_tests tests"
    elif [ "$(echo "$disconnection_percentage < 10" | bc 2>/dev/null)" = "1" ]; then
        log_status "WARNING" "Minor disconnections" "$disconnection_count failures out of $total_tests tests (${disconnection_percentage}%)"
    elif [ "$(echo "$disconnection_percentage < 30" | bc 2>/dev/null)" = "1" ]; then
        log_status "WARNING" "Moderate instability" "$disconnection_count failures out of $total_tests tests (${disconnection_percentage}%)"
    else
        log_status "FAIL" "Severe disconnections" "$disconnection_count failures out of $total_tests tests (${disconnection_percentage}%)"
        stability_issues=true
    fi
    
    # Report velocity analysis
    log_status "SUCCESS" "Average connection velocity" "${avg_velocity} requests/second"
    
    if [ "$(echo "$velocity_variance > 1" | bc 2>/dev/null)" = "1" ]; then
        log_status "WARNING" "Velocity consistency" "High variance (${velocity_variance}) - connection speed fluctuates significantly"
    elif [ "$(echo "$velocity_variance > 0.5" | bc 2>/dev/null)" = "1" ]; then
        log_status "WARNING" "Velocity consistency" "Moderate variance (${velocity_variance}) - some speed fluctuation"
    else
        log_status "SUCCESS" "Velocity consistency" "Low variance (${velocity_variance}) - stable connection speed"
    fi
    
    # Comprehensive speed and throughput test (only if connection is healthy)
    if [ "$INTERNATIONAL_HTTPS_COUNT" -gt 0 ] || [ "$CDN_HTTPS_COUNT" -gt 0 ]; then
        printf "${BLUE}Running comprehensive throughput test...${NC}\n"
        
        # Multiple speed tests to detect throttling and measure consistency
        local speed_tests=3
        local speeds=()
        local speed_variance=0
        
        for speed_round in $(seq 1 $speed_tests); do
            printf "Speed test $speed_round/$speed_tests... "
            local test_start=$(date +%s.%N)
            local download_success=0
            local total_bytes=0
            
            # Test with multiple CDN endpoints for better accuracy
            local test_urls=(
                "https://httpbin.org/bytes/1048576"  # 1MB
                "https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.min.js"
                "https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"
            )
            
            for test_url in "${test_urls[@]}"; do
                local file_start=$(date +%s.%N)
                local temp_file="/tmp/speed_test_${speed_round}_$$"
                
                if curl -s --max-time 8 --connect-timeout 3 -o "$temp_file" "$test_url" 2>/dev/null; then
                    local file_end=$(date +%s.%N)
                    local file_size=$(wc -c < "$temp_file" 2>/dev/null || echo "0")
                    local file_duration=$(echo "$file_end - $file_start" | bc 2>/dev/null || echo "1")
                    
                    if [ "$file_size" -gt 0 ] && [ "$(echo "$file_duration > 0" | bc 2>/dev/null)" = "1" ]; then
                        total_bytes=$((total_bytes + file_size))
                        download_success=$((download_success + 1))
                    fi
                    rm -f "$temp_file"
                fi
            done
            
            local test_end=$(date +%s.%N)
            local total_duration=$(echo "$test_end - $test_start" | bc 2>/dev/null || echo "1")
            
            if [ "$download_success" -gt 0 ] && [ "$total_bytes" -gt 0 ]; then
                local speed_bps=$(echo "scale=2; $total_bytes / $total_duration" | bc 2>/dev/null || echo "0")
                local speed_mbps=$(echo "scale=3; $speed_bps / 1048576" | bc 2>/dev/null || echo "0")
                speeds+=("$speed_mbps")
                printf "${speed_mbps} Mbps\n"
            else
                printf "Failed\n"
                speeds+=("0")
            fi
            
            # Small delay between speed tests
            [ "$speed_round" -lt "$speed_tests" ] && sleep 2
        done
        
        # Calculate speed statistics
        local total_speed=0
        local valid_speeds=0
        for speed in "${speeds[@]}"; do
            if [ "$(echo "$speed > 0" | bc 2>/dev/null)" = "1" ]; then
                total_speed=$(echo "$total_speed + $speed" | bc 2>/dev/null || echo "$total_speed")
                valid_speeds=$((valid_speeds + 1))
            fi
        done
        
        if [ "$valid_speeds" -gt 0 ]; then
            local avg_speed=$(echo "scale=3; $total_speed / $valid_speeds" | bc 2>/dev/null || echo "0")
            
            # Calculate speed variance for throttling detection
            local speed_variance_sum=0
            for speed in "${speeds[@]}"; do
                if [ "$(echo "$speed > 0" | bc 2>/dev/null)" = "1" ]; then
                    local diff=$(echo "$speed - $avg_speed" | bc 2>/dev/null || echo "0")
                    local diff_squared=$(echo "$diff * $diff" | bc 2>/dev/null || echo "0")
                    speed_variance_sum=$(echo "$speed_variance_sum + $diff_squared" | bc 2>/dev/null || echo "$speed_variance_sum")
                fi
            done
            local speed_variance=$(echo "scale=3; $speed_variance_sum / $valid_speeds" | bc 2>/dev/null || echo "0")
            
            # Report speed results
            if [ "$(echo "$avg_speed >= 1" | bc 2>/dev/null)" = "1" ]; then
                log_status "SUCCESS" "Average download speed" "${avg_speed} Mbps"
            else
                local avg_kbps=$(echo "scale=2; $avg_speed * 1024" | bc 2>/dev/null || echo "0")
                log_status "WARNING" "Average download speed" "${avg_kbps} Kbps (slow)"
            fi
            
            # Speed consistency analysis
            if [ "$(echo "$speed_variance > 2" | bc 2>/dev/null)" = "1" ]; then
                log_status "WARNING" "Speed consistency" "High variance (${speed_variance}) - possible throttling or congestion"
            elif [ "$(echo "$speed_variance > 0.5" | bc 2>/dev/null)" = "1" ]; then
                log_status "WARNING" "Speed consistency" "Moderate variance (${speed_variance}) - some speed fluctuation"
            else
                log_status "SUCCESS" "Speed consistency" "Low variance (${speed_variance}) - stable throughput"
            fi
            
            # Overall connection quality with combined metrics
            local quality_score=0
            
            # Speed component (40% of score)
            if [ "$(echo "$avg_speed >= 10" | bc 2>/dev/null)" = "1" ]; then
                quality_score=$((quality_score + 40))
            elif [ "$(echo "$avg_speed >= 5" | bc 2>/dev/null)" = "1" ]; then
                quality_score=$((quality_score + 30))
            elif [ "$(echo "$avg_speed >= 1" | bc 2>/dev/null)" = "1" ]; then
                quality_score=$((quality_score + 20))
            else
                quality_score=$((quality_score + 10))
            fi
            
            # Stability component (30% of score)
            if [ "$stability_issues" = "false" ]; then
                quality_score=$((quality_score + 30))
            else
                quality_score=$((quality_score + 15))
            fi
            
            # Consistency component (30% of score)
            if [ "$(echo "$speed_variance < 0.5" | bc 2>/dev/null)" = "1" ] && [ "$(echo "$velocity_variance < 0.5" | bc 2>/dev/null)" = "1" ]; then
                quality_score=$((quality_score + 30))
            elif [ "$(echo "$speed_variance < 2" | bc 2>/dev/null)" = "1" ] && [ "$(echo "$velocity_variance < 1" | bc 2>/dev/null)" = "1" ]; then
                quality_score=$((quality_score + 20))
            else
                quality_score=$((quality_score + 10))
            fi
            
            # Final quality assessment
            if [ "$quality_score" -ge 80 ]; then
                log_status "SUCCESS" "Overall connection quality" "Excellent (score: $quality_score/100)"
            elif [ "$quality_score" -ge 60 ]; then
                log_status "SUCCESS" "Overall connection quality" "Good (score: $quality_score/100)"
            elif [ "$quality_score" -ge 40 ]; then
                log_status "WARNING" "Overall connection quality" "Fair (score: $quality_score/100)"
            else
                log_status "WARNING" "Overall connection quality" "Poor (score: $quality_score/100)"
            fi
        else
            log_status "FAIL" "Speed test" "Unable to measure - connection too unstable for throughput testing"
        fi
    else
        log_status "WARNING" "Speed test" "Skipped - HTTPS connectivity issues prevent accurate measurement"
    fi
}

# Intelligent failure analysis
diagnose_connection_issues() {
    printf "${RED}Connection Issue Diagnosis${NC}\n"
    
    local total_international=${#INTERNATIONAL_SITES[@]}
    local total_regional=${#REGIONAL_SITES[@]}
    local total_cdn=${#CDN_SITES[@]}
    
    # Primary connection issues
    if [ "$PRIMARY_CONNECTION_STATUS" = "NO_CONNECTION" ]; then
        printf "${RED}[DIAGNOSIS]${NC} System has no internet connection\n"
        printf "  → No active network interfaces found\n"
        printf "  → Check WiFi/Ethernet cable connection\n"
        printf "  → Restart network services\n"
        return
    fi
    
    if [ "$PRIMARY_CONNECTION_STATUS" = "VPN_ONLY" ]; then
        printf "${YELLOW}[DIAGNOSIS]${NC} Only VPN connection active\n"
        printf "  → Primary WiFi/Ethernet connection is down\n"
        printf "  → Running through VPN/tunnel only\n"
        printf "  → May cause performance issues\n"
    fi
    
    # Gateway issues
    if [ "$GATEWAY_STATUS" = "FAIL" ]; then
        printf "${RED}[DIAGNOSIS]${NC} Local network gateway unreachable\n"
        printf "  → Router/modem may be down\n"
        printf "  → Network configuration issue\n"
        printf "  → Check router power and cables\n"
        return
    fi
    
    # DNS issues
    if [ "$DNS_PING_STATUS" = "FAIL" ]; then
        printf "${RED}[DIAGNOSIS]${NC} DNS server connectivity issues\n"
        if [ "$DNS_RESOLUTION_STATUS" = "FAIL" ]; then
            printf "  → DNS servers unreachable AND resolution failing\n"
            printf "  → ISP DNS may be down\n"
            printf "  → Try switching to alternative DNS (1.1.1.1, 8.8.8.8)\n"
        else
            printf "  → DNS servers unreachable but resolution working\n"
            printf "  → Using cached DNS or alternative resolvers\n"
        fi
        return
    fi
    
    # Analyze traffic patterns
    local https_blocked=false
    local complete_blocking=false
    local selective_blocking=false
    
    # Check international sites
    if [ "$INTERNATIONAL_HTTPS_COUNT" -eq 0 ] && [ "$INTERNATIONAL_PING_COUNT" -gt 0 ]; then
        https_blocked=true
    elif [ "$INTERNATIONAL_HTTPS_COUNT" -eq 0 ] && [ "$INTERNATIONAL_PING_COUNT" -eq 0 ]; then
        complete_blocking=true
    elif [ "$INTERNATIONAL_HTTPS_COUNT" -gt 0 ] && [ "$INTERNATIONAL_PING_COUNT" -gt 0 ]; then
        selective_blocking=true
    fi
    
    # Specific diagnoses
    if [ "$complete_blocking" = true ]; then
        printf "${RED}[DIAGNOSIS]${NC} Complete internet blocking detected\n"
        printf "  → Both ping and HTTPS failing for all sites\n"
        printf "  → ISP may be experiencing outage\n"
        printf "  → Check ISP status or try mobile hotspot\n"
        
    elif [ "$https_blocked" = true ]; then
        if [ "$CDN_HTTPS_COUNT" -eq 0 ] && [ "$REGIONAL_HTTPS_COUNT" -eq 0 ]; then
            printf "${RED}[DIAGNOSIS]${NC} Deep Packet Inspection (DPI) blocking detected\n"
            printf "  → HTTPS traffic is being filtered/blocked\n"
            printf "  → Affects both international and regional sites\n"
            printf "  → Government/ISP level filtering active\n"
            printf "  → Consider using VPN or DNS-over-HTTPS\n"
        else
            printf "${YELLOW}[DIAGNOSIS]${NC} Selective HTTPS filtering detected\n"
            printf "  → International HTTPS blocked but some regional sites work\n"
            printf "  → Geographic or content-based filtering\n"
            printf "  → VPN may help access blocked content\n"
        fi
        
    elif [ "$CDN_HTTPS_COUNT" -eq 0 ] && [ "$INTERNATIONAL_HTTPS_COUNT" -gt 0 ]; then
        printf "${YELLOW}[DIAGNOSIS]${NC} CDN/Content delivery network blocking\n"
        printf "  → CDN services specifically blocked\n"
        printf "  → May affect website loading and performance\n"
        printf "  → Some applications may not work properly\n"
        
    elif [ "$selective_blocking" = true ]; then
        printf "${YELLOW}[DIAGNOSIS]${NC} Intermittent connection issues detected\n"
        if [ "$VPN_ONLY_CONNECTION" = true ]; then
            printf "  → VPN connection may be unstable\n"
            printf "  → Try reconnecting VPN or switching servers\n"
        else
            printf "  → Network may be congested or unstable\n"
            printf "  → Some sites timing out randomly\n"
            printf "  → Could be ISP throttling or server issues\n"
        fi
        
    else
        # Connection working but failed overall test
        if [ "$REGIONAL_HTTPS_COUNT" -gt 0 ] || [ "$INTERNATIONAL_HTTPS_COUNT" -gt 0 ]; then
            printf "${GREEN}[DIAGNOSIS]${NC} Partial connectivity detected\n"
            printf "  → Some sites working, others may be temporarily down\n"
            printf "  → Individual server issues rather than systematic blocking\n"
            printf "  → Connection is generally functional\n"
        fi
    fi
    
    # Additional context
    if [ "$INTERNATIONAL_PING_COUNT" -gt 0 ] && [ "$INTERNATIONAL_HTTPS_COUNT" -eq 0 ]; then
        printf "${BLUE}[INFO]${NC} Ping works but HTTPS doesn't - indicates:\n"
        printf "  → Port 443 (HTTPS) filtering\n"
        printf "  → SNI (Server Name Indication) blocking\n"
        printf "  → TLS/SSL traffic inspection\n"
    fi
    
    if [ "$VPN_ONLY_CONNECTION" = true ]; then
        printf "${BLUE}[INFO]${NC} Running on VPN-only connection:\n"
        printf "  → May have different filtering rules\n"
        printf "  → Performance may be slower\n"
        printf "  → Some local services may not work\n"
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    local overall_status=""
    
    case "$MODE" in
        test)
            if [ "$SILENT_MODE" != "true" ]; then
                message 43 ↔ "Quick internet connectivity check"
            fi
            if quick_check; then
                overall_status=true
            else
                overall_status=false
            fi
            ;;
            
        is-online)
            # Silent boolean check - no start message
            if quick_check; then
                overall_status=true
            else
                overall_status=false
            fi
            ;;
            
        diagnose)
            message 44 "Full internet connection diagnostic"
            
            overall_status=true
            # Always include connection quality in diagnose mode, no need for separate debug flag
            test_network_interface || overall_status=false
            quick_check || overall_status=false
            test_dns_servers || overall_status=false
            test_international_sites || overall_status=false
            test_regional_sites || overall_status=false
            test_cdn_connectivity || overall_status=false
            ask_to_run_command "Run stability tests? (~30sec)" test_connection_quality
            ;;
    esac
    
    # Summary (except in check mode)
    if [ "$MODE" != "is-online" ] && [ "$SILENT_MODE" != "true" ]; then
        if [ "$overall_status" = "true" ]; then
            printf "${GREEN}[SUCCESS]${NC} Internet connection working properly\n"
        elif [ "$overall_status" = "false" ]; then
            printf "${RED}[FAILED]${NC} Internet connection has issues\n"
            # Run intelligent diagnosis if we have test results
            if [ "$MODE" = "diagnose" ]; then
                diagnose_connection_issues
            fi
        else
            printf "${RED}[ERROR]${NC} Incomplete operation, Script execution failed.\n"
        fi
    fi
    
    # Exit with appropriate code
    [ "$overall_status" = "true" ] && exit 0 || exit 1
}

# Run the script
main "$@"