#!/bin/bash

# Connection quality and speed testing functions

# Test connection quality and speed
test_connection_quality() {
    printf "${BLUE}Connection Quality & Speed${NC}\n"

    # Extended latency tests with stability analysis
    local stability_issues=false
    
    # Detect ping command options
    local ping_timeout_opt=""
    if ping -W 1 -c 1 127.0.0.1 >/dev/null 2>&1; then
        ping_timeout_opt="-W 10"
    elif ping -t 10 -c 1 127.0.0.1 >/dev/null 2>&1; then
        ping_timeout_opt="-t 10"
    fi
    
    if [ -n "$LOCAL_GATEWAY" ]; then
        printf "${BLUE}Testing gateway stability...${NC}\n"
        local gateway_stats=$(timeout 12s ping -c 10 $ping_timeout_opt "$LOCAL_GATEWAY" 2>/dev/null || ping -c 10 "$LOCAL_GATEWAY" 2>/dev/null)
        local gateway_avg=$(echo "$gateway_stats" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
        local gateway_loss=$(echo "$gateway_stats" | grep "packet loss" | awk '{print $6}' | sed 's/%//' 2>/dev/null)
        
        if [ -n "$gateway_avg" ]; then
            log_status "SUCCESS" "Gateway average latency" "${gateway_avg}ms"
            if [ -n "$gateway_loss" ] && [ "$(float_compare "$gateway_loss" ">" "0")" = "1" ]; then
                log_status "WARNING" "Gateway packet loss" "${gateway_loss}%"
                stability_issues=true
            fi
        fi
    fi
    
    # DNS stability test
    printf "${BLUE}Testing DNS stability...${NC}\n"
    local dns_stats=$(timeout 12s ping -c 10 $ping_timeout_opt 8.8.8.8 2>/dev/null || ping -c 10 8.8.8.8 2>/dev/null)
    local dns_avg=$(echo "$dns_stats" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
    local dns_loss=$(echo "$dns_stats" | grep "packet loss" | awk '{print $6}' | sed 's/%//' 2>/dev/null)
    
    if [ -n "$dns_avg" ]; then
        log_status "SUCCESS" "DNS average latency" "${dns_avg}ms"
        if [ -n "$dns_loss" ] && [ "$(float_compare "$dns_loss" ">" "0")" = "1" ]; then
            log_status "WARNING" "DNS packet loss" "${dns_loss}%"
            stability_issues=true
        fi
    fi
    
    # International connectivity stability
    printf "${BLUE}Testing international stability...${NC}\n"
    local intl_stats=$(timeout 12s ping -c 10 $ping_timeout_opt google.com 2>/dev/null || ping -c 10 google.com 2>/dev/null)
    local intl_avg=$(echo "$intl_stats" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
    local intl_loss=$(echo "$intl_stats" | grep "packet loss" | awk '{print $6}' | sed 's/%//' 2>/dev/null)
    
    if [ -n "$intl_avg" ]; then
        log_status "SUCCESS" "International average latency" "${intl_avg}ms"
        if [ -n "$intl_loss" ] && [ "$(float_compare "$intl_loss" ">" "0")" = "1" ]; then
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
        local round_duration=$(calculate_duration "$round_start" "$round_end")
        local round_velocity=$(float_divide "$quick_test_success" "$round_duration")
        velocities+=("$round_velocity")
        
        printf "Success: $quick_test_success/$quick_tests, Velocity: ${round_velocity} req/sec\n"
        sleep 1  # Rest between rounds
    done
    
    # Calculate velocity statistics
    local total_velocity=0
    local velocity_count=${#velocities[@]}
    for vel in "${velocities[@]}"; do
        total_velocity=$(float_add "$total_velocity" "$vel")
    done
    
    local avg_velocity=$(calculate_average "$total_velocity" "$velocity_count")
    
    # Calculate velocity variance for consistency analysis
    local variance_sum=0
    for vel in "${velocities[@]}"; do
        local diff=$(float_subtract "$vel" "$avg_velocity")
        local diff_squared=$(float_multiply "$diff" "$diff")
        variance_sum=$(float_add "$variance_sum" "$diff_squared")
    done
    local velocity_variance=$(calculate_variance "$variance_sum" "$velocity_count")
    
    # Report disconnection analysis
    local total_tests=$((test_rounds * quick_tests))
    local success_rate=$((total_tests - disconnection_count))
    local disconnection_percentage=$(calculate_percentage "$disconnection_count" "$total_tests")
    
    if [ "$disconnection_count" -eq 0 ]; then
        log_status "SUCCESS" "Connection stability" "No disconnections detected in $total_tests tests"
    elif [ "$(float_compare "$disconnection_percentage" "<" "10")" = "1" ]; then
        log_status "WARNING" "Minor disconnections" "$disconnection_count failures out of $total_tests tests (${disconnection_percentage}%)"
    elif [ "$(float_compare "$disconnection_percentage" "<" "30")" = "1" ]; then
        log_status "WARNING" "Moderate instability" "$disconnection_count failures out of $total_tests tests (${disconnection_percentage}%)"
    else
        log_status "FAIL" "Severe disconnections" "$disconnection_count failures out of $total_tests tests (${disconnection_percentage}%)"
        stability_issues=true
    fi
    
    # Report velocity analysis
    log_status "SUCCESS" "Average connection velocity" "${avg_velocity} requests/second"
    
    if [ "$(float_compare "$velocity_variance" ">" "1")" = "1" ]; then
        log_status "WARNING" "Velocity consistency" "High variance (${velocity_variance}) - connection speed fluctuates significantly"
    elif [ "$(float_compare "$velocity_variance" ">" "0.5")" = "1" ]; then
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
                    local file_duration=$(calculate_duration "$file_start" "$file_end")
                    
                    if [ "$file_size" -gt 0 ] && [ "$(float_compare "$file_duration" ">" "0")" = "1" ]; then
                        total_bytes=$((total_bytes + file_size))
                        download_success=$((download_success + 1))
                    fi
                    rm -f "$temp_file"
                fi
            done
            
            local test_end=$(date +%s.%N)
            local total_duration=$(calculate_duration "$test_start" "$test_end")
            
            if [ "$download_success" -gt 0 ] && [ "$total_bytes" -gt 0 ]; then
                local speed_mbps=$(bytes_to_mbps "$total_bytes" "$total_duration")
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
            if [ "$(float_compare "$speed" ">" "0")" = "1" ]; then
                total_speed=$(float_add "$total_speed" "$speed")
                valid_speeds=$((valid_speeds + 1))
            fi
        done
        
        if [ "$valid_speeds" -gt 0 ]; then
            local avg_speed=$(calculate_average "$total_speed" "$valid_speeds")
            
            # Calculate speed variance for throttling detection
            local speed_variance_sum=0
            for speed in "${speeds[@]}"; do
                if [ "$(float_compare "$speed" ">" "0")" = "1" ]; then
                    local diff=$(float_subtract "$speed" "$avg_speed")
                    local diff_squared=$(float_multiply "$diff" "$diff")
                    speed_variance_sum=$(float_add "$speed_variance_sum" "$diff_squared")
                fi
            done
            local speed_variance=$(calculate_variance "$speed_variance_sum" "$valid_speeds")
            
            # Report speed results
            if [ "$(float_compare "$avg_speed" ">=" "1")" = "1" ]; then
                log_status "SUCCESS" "Average download speed" "${avg_speed} Mbps"
            else
                local avg_kbps=$(float_multiply "$avg_speed" "1024")
                log_status "WARNING" "Average download speed" "${avg_kbps} Kbps (slow)"
            fi
            
            # Speed consistency analysis
            if [ "$(float_compare "$speed_variance" ">" "2")" = "1" ]; then
                log_status "WARNING" "Speed consistency" "High variance (${speed_variance}) - possible throttling or congestion"
            elif [ "$(float_compare "$speed_variance" ">" "0.5")" = "1" ]; then
                log_status "WARNING" "Speed consistency" "Moderate variance (${speed_variance}) - some speed fluctuation"
            else
                log_status "SUCCESS" "Speed consistency" "Low variance (${speed_variance}) - stable throughput"
            fi
            
            # Overall connection quality with combined metrics
            local quality_score=0
            
            # Speed component (40% of score)
            if [ "$(float_compare "$avg_speed" ">=" "10")" = "1" ]; then
                quality_score=$((quality_score + 40))
            elif [ "$(float_compare "$avg_speed" ">=" "5")" = "1" ]; then
                quality_score=$((quality_score + 30))
            elif [ "$(float_compare "$avg_speed" ">=" "1")" = "1" ]; then
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
            if [ "$(float_compare "$speed_variance" "<" "0.5")" = "1" ] && [ "$(float_compare "$velocity_variance" "<" "0.5")" = "1" ]; then
                quality_score=$((quality_score + 30))
            elif [ "$(float_compare "$speed_variance" "<" "2")" = "1" ] && [ "$(float_compare "$velocity_variance" "<" "1")" = "1" ]; then
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
