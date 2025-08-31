#!/bin/bash

# Optimized connectivity tests for Alpine container environment

# Quick connectivity test - this is the primary function for the is-online command
quick_check() {
    local timeout=$QUICK_TIMEOUT
    local overall_status=true
    local start_time=$(date +%s.%N)
    
    # Test gateway
    get_gateway
    if [ -n "$LOCAL_GATEWAY" ]; then
        local test_start=$(date +%s.%N)
        if ping -c $PING_COUNT -W "$timeout" "$LOCAL_GATEWAY" >/dev/null 2>&1; then
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
        log_status "FAIL" "Gateway detection" "No default gateway found"
        GATEWAY_STATUS="FAIL"
        overall_status=false
    fi
    
    # Test DNS
    local test_start=$(date +%s.%N)
    if ping -c $PING_COUNT -W "$timeout" "$QUICK_DNS" >/dev/null 2>&1; then
        local test_end=$(date +%s.%N)
        local duration=$(calculate_duration "$test_start" "$test_end")
        log_status "SUCCESS" "DNS server ping" "$QUICK_DNS" "${duration}s"
        DNS_STATUS="SUCCESS"
    else
        local test_end=$(date +%s.%N)
        local duration=$(calculate_duration "$test_start" "$test_end")
        log_status "FAIL" "DNS server ping" "$QUICK_DNS (timeout after ${timeout}s)" "${duration}s"
        DNS_STATUS="FAIL"
        overall_status=false
    fi
    
    # Test internet
    local test_start=$(date +%s.%N)
    # Use multiple attempts with different timeouts to be more reliable
    if curl -s --max-time $QUICK_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$QUICK_SITE" >/dev/null 2>&1 || \
       wget -q --timeout=$QUICK_TIMEOUT --tries=1 -O /dev/null "https://$QUICK_SITE" >/dev/null 2>&1; then
        local test_end=$(date +%s.%N)
        local duration=$(calculate_duration "$test_start" "$test_end")
        log_status "SUCCESS" "Internet HTTPS" "$QUICK_SITE" "${duration}s"
        HTTP_STATUS="SUCCESS"
    else
        # Try ping if HTTPS fails
        if ping -c $PING_COUNT -W $QUICK_TIMEOUT "$QUICK_SITE" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "FAIL" "Internet connectivity" "$QUICK_SITE - ping OK but HTTPS blocked/filtered" "${duration}s"
            HTTP_STATUS="BLOCKED"
            overall_status=false
        else
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "FAIL" "Internet connectivity" "$QUICK_SITE - both ping and HTTPS failed" "${duration}s"
            HTTP_STATUS="FAIL"
            overall_status=false
        fi
    fi
    
    local end_time=$(date +%s.%N)
    local total_duration=$(calculate_duration "$start_time" "$end_time")
    if [ "$MODE" = "diagnose" ] && [ "$SILENT_MODE" != "true" ]; then
        echo "Quick check completed in ${total_duration}s"
    fi
    
    return $([[ "$overall_status" = true ]] && echo 0 || echo 1)
}

# Test DNS servers for resolution
test_dns_servers() {
    if [ "$SILENT_MODE" != "true" ]; then
        echo ""
        printf "${WHITE}DNS Server Tests ${NC}\n"
    fi
    
    local dns_servers_working=false
    
    for dns in "${DNS_SERVERS[@]}"; do
        local test_start=$(date +%s.%N)
        
        # First test: Can we ping the DNS server?
        if ping -c $PING_COUNT -W $DNS_PING_TIMEOUT "$dns" >/dev/null 2>&1; then
            log_status "SUCCESS" "DNS server" "$dns is reachable"
            
            # Second test: Can we resolve domains using this DNS?
            local resolved=false
            
            # Try multiple resolution methods
            if command -v nslookup >/dev/null 2>&1; then
                if timeout $DNS_RESOLUTION_TIMEOUT nslookup $DNS_TEST_DOMAIN "$dns" >/dev/null 2>&1; then
                    resolved=true
                fi
            elif command -v dig >/dev/null 2>&1; then
                if timeout $DNS_RESOLUTION_TIMEOUT dig @"$dns" $DNS_TEST_DOMAIN +short >/dev/null 2>&1; then
                    resolved=true
                fi
            elif command -v host >/dev/null 2>&1; then
                if timeout $DNS_RESOLUTION_TIMEOUT host $DNS_TEST_DOMAIN "$dns" >/dev/null 2>&1; then
                    resolved=true
                fi
            fi
            
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            
            if [ "$resolved" = "true" ]; then
                log_status "SUCCESS" "DNS resolution" "Using $dns" "${duration}s"
                dns_servers_working=true
            else
                log_status "FAIL" "DNS resolution" "Using $dns - server reached but resolution failed" "${duration}s"
            fi
        else
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "FAIL" "DNS server" "$dns unreachable" "${duration}s"
        fi
    done
    
    # Even if direct DNS ping fails, check if DNS resolution still works
    if [ "$dns_servers_working" = "false" ]; then
        if command -v nslookup >/dev/null 2>&1 && nslookup $DNS_TEST_DOMAIN >/dev/null 2>&1; then
            log_status "SUCCESS" "DNS resolution" "System DNS resolution works" 
            dns_servers_working=true
        elif command -v dig >/dev/null 2>&1 && dig $DNS_TEST_DOMAIN +short >/dev/null 2>&1; then
            log_status "SUCCESS" "DNS resolution" "System DNS resolution works"
            dns_servers_working=true
        elif command -v host >/dev/null 2>&1 && host $DNS_TEST_DOMAIN >/dev/null 2>&1; then
            log_status "SUCCESS" "DNS resolution" "System DNS resolution works"
            dns_servers_working=true
        fi
    fi
    
    return $([[ "$dns_servers_working" = true ]] && echo 0 || echo 1)
}

# Test access to international sites
test_international_sites() {
    if [ "$SILENT_MODE" != "true" ]; then
        echo ""
        printf "${WHITE}International Site Access ${NC}\n"
    fi
    
    local sites_accessible=false
    local sites_tested=0
    local sites_success=0
    
    for site in "${INTERNATIONAL_SITES[@]}"; do
        local test_start=$(date +%s.%N)
        sites_tested=$((sites_tested + 1))
        
        # Try HTTPS first
        if curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$site" >/dev/null 2>&1 || \
           wget -q --timeout=$SITE_HTTPS_TIMEOUT --tries=1 -O /dev/null "https://$site" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "SUCCESS" "HTTPS access" "$site" "${duration}s"
            sites_accessible=true
            sites_success=$((sites_success + 1))
        else
            # Try ping if HTTPS fails
            if ping -c 1 -W 2 "$site" >/dev/null 2>&1; then
                local test_end=$(date +%s.%N)
                local duration=$(calculate_duration "$test_start" "$test_end")
                log_status "WARNING" "HTTPS blocked" "$site (ping works but HTTPS fails)" "${duration}s"
            else
                local test_end=$(date +%s.%N)
                local duration=$(calculate_duration "$test_start" "$test_end")
                log_status "FAIL" "Site access" "$site (unreachable)" "${duration}s"
            fi
        fi
    done
    
    if [ "$sites_tested" -gt 0 ]; then
        local success_rate=$((sites_success * 100 / sites_tested))
        if [ "$SILENT_MODE" != "true" ]; then
            echo "International sites accessible: $sites_success/$sites_tested ($success_rate%)"
        fi
    fi
    
    return $([[ "$sites_accessible" = true ]] && echo 0 || echo 1)
}

# Test access to regional sites (Iran)
test_regional_sites() {
    if [ "$SILENT_MODE" != "true" ]; then
        echo ""
        printf "${WHITE}Regional Site Access ${NC}\n"
    fi
    
    local sites_accessible=false
    local sites_tested=0
    local sites_success=0
    
    for site in "${REGIONAL_SITES[@]}"; do
        local test_start=$(date +%s.%N)
        sites_tested=$((sites_tested + 1))
        
        # Try HTTPS first
        if curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$site" >/dev/null 2>&1 || \
           wget -q --timeout=$SITE_HTTPS_TIMEOUT --tries=1 -O /dev/null "https://$site" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "SUCCESS" "HTTPS access" "$site" "${duration}s"
            sites_accessible=true
            sites_success=$((sites_success + 1))
        else
            # Try ping if HTTPS fails
            if ping -c 1 -W 2 "$site" >/dev/null 2>&1; then
                local test_end=$(date +%s.%N)
                local duration=$(calculate_duration "$test_start" "$test_end")
                log_status "WARNING" "HTTPS blocked" "$site (ping works but HTTPS fails)" "${duration}s"
            else
                local test_end=$(date +%s.%N)
                local duration=$(calculate_duration "$test_start" "$test_end")
                log_status "FAIL" "Site access" "$site (unreachable)" "${duration}s"
            fi
        fi
    done
    
    if [ "$sites_tested" -gt 0 ]; then
        local success_rate=$((sites_success * 100 / sites_tested))
        if [ "$SILENT_MODE" != "true" ]; then
            echo "Regional sites accessible: $sites_success/$sites_tested ($success_rate%)"
        fi
    fi
    
    return $([[ "$sites_accessible" = true ]] && echo 0 || echo 1)
}

# Test access to CDN sites
test_cdn_connectivity() {
    if [ "$SILENT_MODE" != "true" ]; then
        echo ""
        printf "${WHITE}CDN Access ${NC}\n"
    fi
    
    local sites_accessible=false
    local sites_tested=0
    local sites_success=0
    
    for site in "${CDN_SITES[@]}"; do
        local test_start=$(date +%s.%N)
        sites_tested=$((sites_tested + 1))
        
        # Try HTTPS first
        if curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$site" >/dev/null 2>&1 || \
           wget -q --timeout=$SITE_HTTPS_TIMEOUT --tries=1 -O /dev/null "https://$site" >/dev/null 2>&1; then
            local test_end=$(date +%s.%N)
            local duration=$(calculate_duration "$test_start" "$test_end")
            log_status "SUCCESS" "HTTPS access" "$site" "${duration}s"
            sites_accessible=true
            sites_success=$((sites_success + 1))
        else
            # Try ping if HTTPS fails
            if ping -c 1 -W 2 "$site" >/dev/null 2>&1; then
                local test_end=$(date +%s.%N)
                local duration=$(calculate_duration "$test_start" "$test_end")
                log_status "WARNING" "HTTPS blocked" "$site (ping works but HTTPS fails)" "${duration}s"
            else
                local test_end=$(date +%s.%N)
                local duration=$(calculate_duration "$test_start" "$test_end")
                log_status "FAIL" "Site access" "$site (unreachable)" "${duration}s"
            fi
        fi
    done
    
    if [ "$sites_tested" -gt 0 ]; then
        local success_rate=$((sites_success * 100 / sites_tested))
        if [ "$SILENT_MODE" != "true" ]; then
            echo "CDN sites accessible: $sites_success/$sites_tested ($success_rate%)"
        fi
    fi
    
    return $([[ "$sites_accessible" = true ]] && echo 0 || echo 1)
}

# Test connection quality using lightweight methods
test_connection_quality() {
    if [ "$SILENT_MODE" != "true" ]; then
        echo ""
        printf "${WHITE}Connection Quality Analysis ${NC}\n"
    fi
    
    # Simplified latency test using ping
    local latency_target="$LATENCY_TEST_SITE"
    if [ "$SILENT_MODE" != "true" ]; then
        echo "Measuring latency to $latency_target..."
    fi
    
    # Run pings to measure latency and packet loss
    local ping_output=$(ping -c $LATENCY_TEST_COUNT -W $LATENCY_TIMEOUT "$latency_target" 2>&1)
    local ping_success=$?
    
    if [ $ping_success -eq 0 ]; then
        # Extract average latency - Alpine-friendly without -P grep option
        local avg_latency=$(echo "$ping_output" | grep "avg" | awk -F'/' '{print $5}')
        
        # Extract packet loss percentage - Try different formats for Alpine/BusyBox compatibility
        local packet_loss=""
        # Try different packet loss formats
        if echo "$ping_output" | grep -q "packet loss"; then
            # Format: "X% packet loss"
            packet_loss=$(echo "$ping_output" | grep "packet loss" | sed -E 's/.*([0-9]+)%.*/\1/')
        elif echo "$ping_output" | grep -q "packets transmitted"; then
            # Calculate from transmitted/received if direct percentage isn't available
            local transmitted=$(echo "$ping_output" | grep "packets transmitted" | awk '{print $1}')
            local received=$(echo "$ping_output" | grep "packets transmitted" | awk '{print $4}')
            if [ -n "$transmitted" ] && [ -n "$received" ] && [ "$transmitted" -gt 0 ]; then
                packet_loss=$(( 100 - (received * 100 / transmitted) ))
            fi
        fi
        
        if [ -n "$avg_latency" ]; then
            if (( $(echo "$avg_latency < $GOOD_LATENCY_THRESHOLD" | bc -l) )); then
                log_status "SUCCESS" "Latency" "${avg_latency}ms - Good (<${GOOD_LATENCY_THRESHOLD}ms)"
            elif (( $(echo "$avg_latency < $MODERATE_LATENCY_THRESHOLD" | bc -l) )); then
                log_status "WARNING" "Latency" "${avg_latency}ms - Moderate (${GOOD_LATENCY_THRESHOLD}-${MODERATE_LATENCY_THRESHOLD}ms)"
            else
                log_status "FAIL" "Latency" "${avg_latency}ms - Poor (>${MODERATE_LATENCY_THRESHOLD}ms)"
            fi
        fi
        
        # Check if packet_loss is a numeric value before comparing
        if [ -n "$packet_loss" ] && [[ "$packet_loss" =~ ^[0-9]+$ ]]; then
            if [ "$packet_loss" -eq 0 ]; then
                log_status "SUCCESS" "Packet Loss" "0% - No packet loss"
            elif [ "$packet_loss" -lt $ACCEPTABLE_PACKET_LOSS ]; then
                log_status "WARNING" "Packet Loss" "${packet_loss}% - Minor packet loss"
            else
                log_status "FAIL" "Packet Loss" "${packet_loss}% - Significant packet loss"
            fi
        else
            # If we couldn't parse the packet loss properly, just show the raw value
            log_status "INFO" "Packet Loss" "Could not determine percentage"
        fi
    else
        log_status "FAIL" "Connectivity Test" "Unable to measure latency to $latency_target"
    fi
    
    # Basic HTTP throughput test
    if [ "$SILENT_MODE" != "true" ]; then
        echo "Testing download performance..."
    fi
    
    # Test small file download speed
    local download_start=$(date +%s.%N)
    local download_success=false
    local download_size=0
    local download_time=0
    
    # Try to download a small file and measure the time
    if command -v curl >/dev/null 2>&1; then
        # Use a reliable speed test file
        local test_file_url="$SPEED_TEST_URL"
        local curl_output=$(curl -s -w "%{time_total} %{size_download}" -o /dev/null "$test_file_url" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            download_success=true
            download_time=$(echo "$curl_output" | cut -d' ' -f1)
            download_size=$(echo "$curl_output" | cut -d' ' -f2)
        fi
    fi
    
    # If curl failed, try wget
    if [ "$download_success" = false ] && command -v wget >/dev/null 2>&1; then
        local test_file_url="$SPEED_TEST_URL"
        local download_start=$(date +%s.%N)
        wget -q -O /dev/null "$test_file_url" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            local download_end=$(date +%s.%N)
            download_success=true
            download_time=$(calculate_duration "$download_start" "$download_end")
            download_size=$SPEED_TEST_FILE_SIZE  # 1MB in bytes
        fi
    fi
    
    if [ "$download_success" = true ] && [ "$download_size" -gt 0 ] && [ $(echo "$download_time > 0" | bc -l) -eq 1 ]; then
        # Calculate speed in KB/s and then convert to Mbps
        local speed_kbps=$(echo "scale=2; $download_size / 1024 / $download_time" | bc)
        local speed_mbps=$(echo "scale=2; $speed_kbps / 125" | bc)  # 125 KB/s = 1 Mbps
        
        if (( $(echo "$speed_mbps > $GOOD_SPEED_THRESHOLD" | bc -l) )); then
            log_status "SUCCESS" "Download Speed" "${speed_mbps} Mbps - Good (>$GOOD_SPEED_THRESHOLD Mbps)"
        elif (( $(echo "$speed_mbps > $MODERATE_SPEED_THRESHOLD" | bc -l) )); then
            log_status "WARNING" "Download Speed" "${speed_mbps} Mbps - Moderate ($MODERATE_SPEED_THRESHOLD-$GOOD_SPEED_THRESHOLD Mbps)"
        else
            log_status "FAIL" "Download Speed" "${speed_mbps} Mbps - Poor (<$MODERATE_SPEED_THRESHOLD Mbps)"
        fi
    else
        log_status "FAIL" "Download Test" "Unable to measure download speed"
    fi
    
    return 0
}
