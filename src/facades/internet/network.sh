#!/bin/bash

# Network utility functions for internet connectivity checker

# Get default gateway using native methods
fac_int_get_gateway() {
    LOCAL_GATEWAY=""
    
    # Try /proc/net/route first (Linux standard)
    if [ -f "/proc/net/route" ]; then
        # Parse routing table - look for default route (destination 00000000)
        LOCAL_GATEWAY=$(awk '/^[^\t]*\t00000000\t/ {print $3}' /proc/net/route 2>/dev/null | head -1)
        if [ -n "$LOCAL_GATEWAY" ]; then
            # Convert hex to decimal IP
            LOCAL_GATEWAY=$(printf "%d.%d.%d.%d" 0x${LOCAL_GATEWAY:6:2} 0x${LOCAL_GATEWAY:4:2} 0x${LOCAL_GATEWAY:2:2} 0x${LOCAL_GATEWAY:0:2} 2>/dev/null)
        fi
    fi
    
    # Fallback: try to extract from route command if available
    if [ -z "$LOCAL_GATEWAY" ] && command -v route >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            LOCAL_GATEWAY=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}' | head -1)
        else
            # Linux with route command
            LOCAL_GATEWAY=$(route -n 2>/dev/null | awk '/^0.0.0.0/ {print $2}' | head -1)
        fi
    fi
    
    # Last resort: try netstat if available
    if [ -z "$LOCAL_GATEWAY" ] && command -v netstat >/dev/null 2>&1; then
        LOCAL_GATEWAY=$(netstat -rn 2>/dev/null | awk '/^0.0.0.0|^default/ {print $2}' | head -1)
    fi
    
    # Final fallback: assume common gateway patterns
    if [ -z "$LOCAL_GATEWAY" ]; then
        # Try to ping common gateways to find one that responds
        for gw in "192.168.1.1" "192.168.0.1" "10.0.0.1" "172.16.0.1"; do
            if ping -c 1 -W 1 "$gw" >/dev/null 2>&1 || ping -c 1 -t 1 "$gw" >/dev/null 2>&1; then
                LOCAL_GATEWAY="$gw"
                break
            fi
        done
    fi
}

# Test network interface using native methods
fac_int_test_network_interface() {
    if [ "$MODE" != "test" ]; then
        printf "${BLUE}Network Interface Status${NC}\n"
    fi
    
    local primary_connection_found=false
    local interfaces_checked=0
    
    # Method 1: Use /sys/class/net (Linux)
    if [ -d "/sys/class/net" ]; then
        for iface_path in /sys/class/net/*; do
            [ ! -d "$iface_path" ] && continue
            
            local iface=$(basename "$iface_path")
            # Skip loopback
            [ "$iface" = "lo" ] && continue
            
            interfaces_checked=$((interfaces_checked + 1))
            
            # Check if interface is up
            local operstate=""
            if [ -f "$iface_path/operstate" ]; then
                operstate=$(cat "$iface_path/operstate" 2>/dev/null)
            fi
            
            if [ "$operstate" = "up" ]; then
                # Get IP address from /proc/net/fib_trie or by parsing system
                local ip=""
                
                # Try to get IP from /proc/net/fib_trie
                if [ -f "/proc/net/fib_trie" ]; then
                    # This is complex parsing, let's use a simpler approach
                    ip=$(grep -A 10 "$iface" /proc/net/fib_trie 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | head -1)
                fi
                
                # Fallback: try hostname -I and filter (less reliable but works)
                if [ -z "$ip" ] && command -v hostname >/dev/null 2>&1; then
                    local all_ips=$(hostname -I 2>/dev/null || hostname -i 2>/dev/null)
                    for test_ip in $all_ips; do
                        if [[ "$test_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$test_ip" != "127.0.0.1" ]; then
                            ip="$test_ip"
                            break
                        fi
                    done
                fi
                
                if [ -n "$ip" ]; then
                    local interface_type="Network"
                    case "$iface" in
                        eth*|en*|eno*|enp*) interface_type="Ethernet" ;;
                        wl*|wlan*) interface_type="WiFi" ;;
                        tun*|tap*|ppp*) interface_type="VPN/Tunnel" ;;
                        *) interface_type="Network" ;;
                    esac
                    
                    fac_int_log_status "SUCCESS" "$interface_type interface $iface" "IP: $ip, Status: up"
                    
                    if [[ "$iface" =~ ^(eth|en|wl|wlan) ]]; then
                        primary_connection_found=true
                    fi
                fi
            fi
        done
    fi
    
    # Method 2: Fallback for macOS or systems without /sys
    if [ "$interfaces_checked" -eq 0 ] && command -v ifconfig >/dev/null 2>&1; then
        # Parse ifconfig output (more portable)
        local ifconfig_output=$(ifconfig 2>/dev/null)
        echo "$ifconfig_output" | awk '
        /^[a-z]/ { 
            iface = $1; gsub(/:/, "", iface)
            ip = ""; status = "down"
        }
        /inet / && !/127\.0\.0\.1/ { 
            ip = $2
        }
        /UP.*RUNNING/ {
            status = "up"
        }
        /^$/ {
            if (iface && ip && status == "up" && iface != "lo") {
                type = "Network"
                if (match(iface, /^(eth|en)/)) type = "Ethernet"
                else if (match(iface, /^(wl|wlan)/)) type = "WiFi"
                else if (match(iface, /^(tun|tap|ppp|utun)/)) type = "VPN/Tunnel"
                print type ":" iface ":" ip
            }
            iface = ""; ip = ""; status = "down"
        }' | while IFS=: read -r type iface ip; do
            fac_int_log_status "SUCCESS" "$type interface $iface" "IP: $ip, Status: up"
            if [[ "$type" =~ ^(Ethernet|WiFi)$ ]]; then
                primary_connection_found=true
            fi
            interfaces_checked=$((interfaces_checked + 1))
        done
    fi
    
    # Method 3: Last resort - just check if we can reach the internet
    if [ "$interfaces_checked" -eq 0 ]; then
        fac_int_log_status "WARNING" "Network interface detection" "Unable to enumerate interfaces - using connectivity test"
        
        # Test if we can reach external hosts
        if curl -s --max-time 3 --connect-timeout 2 -I "https://diseec.com" >/dev/null 2>&1; then
            fac_int_log_status "SUCCESS" "Internet connectivity" "External access working (interface details unavailable)"
            primary_connection_found=true
        elif ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -t 2 8.8.8.8 >/dev/null 2>&1; then
            fac_int_log_status "SUCCESS" "Network connectivity" "Can reach external hosts (interface details unavailable)"
            primary_connection_found=true
        fi
    fi
    
    if [ "$primary_connection_found" = "false" ]; then
        fac_int_log_status "FAIL" "Network interfaces" "No active network interfaces with external connectivity found"
        PRIMARY_CONNECTION_STATUS="NO_CONNECTION"
        return 1
    fi
    
    PRIMARY_CONNECTION_STATUS="SUCCESS"
    return 0
}
