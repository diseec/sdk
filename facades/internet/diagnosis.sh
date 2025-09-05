#!/bin/bash

# Diagnostic utilities for internet connectivity issues

# Diagnose connection issues based on test results
sdk_fac_int_diagnose_connection_issues() {
    if [ "$SILENT_MODE" != "true" ]; then
        echo ""
        printf "${WHITE}Connection Diagnosis ${NC}\n"
    fi
    
    # Determine the failure pattern
    if [ "$GATEWAY_STATUS" = "FAIL" ]; then
        sdk_fac_int_log_status "INFO" "Diagnosis" "Network layer issue: Cannot reach gateway"
        sdk_fac_int_log_status "INFO" "Recommendation" "Check container network configuration and Docker network settings"
        return
    fi
    
    if [ "$DNS_STATUS" = "FAIL" ]; then
        # Check if DNS servers are unreachable but internet still works
        if curl -s --max-time $QUICK_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$QUICK_SITE" >/dev/null 2>&1 || \
           curl -s --max-time $QUICK_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$ALTERNATIVE_QUICK_SITE" >/dev/null 2>&1; then
            sdk_fac_int_log_status "INFO" "Diagnosis" "DNS servers unreachable but internet is working"
            sdk_fac_int_log_status "INFO" "Recommendation" "Check your network configuration"
            return
        fi
        
        sdk_fac_int_log_status "INFO" "Diagnosis" "DNS layer issue: Cannot reach DNS servers"
        
        # Check if we can ping an IP but not DNS servers
        if ping -c $PING_COUNT -W $DNS_PING_TIMEOUT $PRIMARY_DNS_SERVER >/dev/null 2>&1 || ping -c $PING_COUNT -W $DNS_PING_TIMEOUT $SECONDARY_DNS_SERVER >/dev/null 2>&1; then
            sdk_fac_int_log_status "INFO" "Recommendation" "DNS servers may be blocked/filtered in your region"
            sdk_fac_int_log_status "INFO" "Recommendation" "Try using alternative DNS servers or DNS over HTTPS/TLS"
        else
            sdk_fac_int_log_status "INFO" "Recommendation" "Check network configuration and firewall settings"
        fi
        return
    fi
    
    if [ "$HTTP_STATUS" = "BLOCKED" ]; then
        sdk_fac_int_log_status "INFO" "Diagnosis" "HTTP(S) traffic is being filtered or blocked"
        sdk_fac_int_log_status "INFO" "Recommendation" "Iran internet censorship detected - consider using a VPN or proxy"
        
        # Check specific services that might be accessible
        sdk_fac_int_log_status "INFO" "Testing" "Checking for partial connectivity..."
        
        if curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$LOCAL_TEST_SITE" >/dev/null 2>&1; then
            sdk_fac_int_log_status "SUCCESS" "Local Services" "Local Iranian services are accessible"
        fi
        
        return
    fi
    
    if [ "$HTTP_STATUS" = "FAIL" ]; then
        sdk_fac_int_log_status "INFO" "Diagnosis" "Internet connectivity issue: Cannot access websites"
        
        # Check if DNS resolution works
        if command -v nslookup >/dev/null 2>&1; then
            if nslookup $DNS_TEST_DOMAIN >/dev/null 2>&1; then
                sdk_fac_int_log_status "INFO" "DNS Resolution" "DNS resolution works but HTTP access fails"
                sdk_fac_int_log_status "INFO" "Recommendation" "HTTP traffic may be blocked by firewall or proxy"
            else
                sdk_fac_int_log_status "INFO" "DNS Resolution" "DNS resolution fails"
                sdk_fac_int_log_status "INFO" "Recommendation" "Check DNS configuration or try alternative DNS"
            fi
        fi
        
        return
    fi
    
    # If we got here, something else is wrong
    sdk_fac_int_log_status "INFO" "Diagnosis" "Unable to determine the exact issue"
    sdk_fac_int_log_status "INFO" "Recommendation" "Run the 'diagnose' command for more detailed analysis"
}

# Advanced diagnostics for MTU and connection issues
sdk_fac_int_advanced_diagnostics() {
    if [ "$SILENT_MODE" != "true" ]; then
        echo ""
        printf "${WHITE}Advanced Network Diagnostics ${NC}\n"
    fi
    
    # Check MTU settings
    if command -v ip >/dev/null 2>&1; then
        local mtu_info=$(ip link | grep -A 1 -E '^[0-9]+:' | grep -v lo | grep mtu | head -1)
        if [ -n "$mtu_info" ]; then
            # Extract MTU value using awk instead of grep -P
            local mtu_value=$(echo "$mtu_info" | grep "mtu" | awk '{for(i=1;i<=NF;i++) if($i ~ /^mtu/) print $(i+1)}')
            if [ -n "$mtu_value" ]; then
                sdk_fac_int_log_status "INFO" "MTU Setting" "Current MTU: $mtu_value"
                if [ "$mtu_value" -lt $GOOD_MTU ]; then
                    sdk_fac_int_log_status "WARNING" "MTU Setting" "MTU is less than acceptable $GOOD_MTU bytes, which may cause issues with some sites"
                fi
            fi
        fi
    fi
    
    # Check for SSL/TLS interception
    if command -v curl >/dev/null 2>&1; then
        # sdk_fac_int_log_status "INFO" "Testing" "Checking for SSL/TLS interception..."
        
        local cert_info=$(curl -sI https://$SSL_CHECK_SITE 2>/dev/null | grep -i "server:" | head -1)
        if [ -n "$cert_info" ]; then
            sdk_fac_int_log_status "INFO" "SSL/TLS Interception" "Server response: $cert_info"
        fi
    fi
    
    # Check traceroute if available
    if command -v traceroute >/dev/null 2>&1; then
        # sdk_fac_int_log_status "INFO" "Testing" "Checking network path to $TRACE_TARGET..."
        
        local traceroute_output=$(timeout ${TRACEROUTE_TIMEOUT}s traceroute -m $TRACEROUTE_MAX_HOPS -q 1 $TRACE_TARGET 2>/dev/null)
        if [ -n "$traceroute_output" ]; then
            # Count hops
            local hop_count=$(echo "$traceroute_output" | grep -c "^[0-9]")
            sdk_fac_int_log_status "INFO" "Network Path" "$hop_count hops to destination"
            
            # Check for timeouts
            local timeout_count=$(echo "$traceroute_output" | grep -c "\* \* \*")
            if [ "$timeout_count" -gt 0 ]; then
                sdk_fac_int_log_status "WARNING" "Network Path" "$timeout_count hops timed out, possible filtering or routing issues"
            fi
        else
            sdk_fac_int_log_status "FAIL" "Network Path" "Unable to trace route to destination"
        fi
    fi
    
    # Check for transparent proxies
    # sdk_fac_int_log_status "INFO" "Testing" "Checking for transparent proxies..."
    
    local proxy_detected=false
    if curl -s -m $PROXY_CHECK_TIMEOUT "https://$IP_CHECK_SERVICE1" >/dev/null 2>&1; then
        local public_ip=$(curl -s -m $PROXY_CHECK_TIMEOUT "https://$IP_CHECK_SERVICE1" 2>/dev/null)
        local alternative_ip=$(curl -s -m $PROXY_CHECK_TIMEOUT "https://$IP_CHECK_SERVICE2" 2>/dev/null)
        
        if [ -n "$public_ip" ] && [ -n "$alternative_ip" ] && [ "$public_ip" != "$alternative_ip" ]; then
            sdk_fac_int_log_status "WARNING" "Proxy Detection" "Different IPs detected from multiple services, possible transparent proxy"
            proxy_detected=true
        elif [ -n "$public_ip" ]; then
            sdk_fac_int_log_status "INFO" "Transparent Proxies" "Public IP: $public_ip"
        fi
    fi
    
    # Check for common Iranian censorship patterns
    # sdk_fac_int_log_status "INFO" "Testing" "Checking for censorship patterns..."
    
    # local censorship_detected=false
    
    # # Try accessing commonly blocked sites
    # if ! curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$CENSORSHIP_TEST_SITE1" >/dev/null 2>&1 && \
    #    ! curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$CENSORSHIP_TEST_SITE2" >/dev/null 2>&1 && \
    #    ! curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$CENSORSHIP_TEST_SITE3" >/dev/null 2>&1; then
    #     # All three major sites are blocked
    #     if curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$LOCAL_TEST_SITE" >/dev/null 2>&1 || \
    #        curl -s --max-time $SITE_HTTPS_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$LOCAL_TEST_SITE2" >/dev/null 2>&1; then
    #         # But Iranian sites work
    #         sdk_fac_int_log_status "WARNING" "Censorship" "Iranian internet filtering detected (international sites blocked, local sites accessible)"
    #         censorship_detected=true
    #     fi
    # fi
    
    # # Summary
    # if [ "$proxy_detected" = true ] || [ "$censorship_detected" = true ]; then
    #     sdk_fac_int_log_status "INFO" "Recommendation" "Connection restricted by regional policies. Consider using VPN or proxy services to access blocked content."
    # fi
    
    return 0
}
