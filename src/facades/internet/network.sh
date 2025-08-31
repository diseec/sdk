#!/bin/bash

# Network utility functions for internet connectivity checker
# Optimized for Alpine Linux container environment

# Get default gateway using native methods
get_gateway() {
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
    
    # Fallback to common container gateways
    if [ -z "$LOCAL_GATEWAY" ]; then
        # Try to ping common gateway patterns to find one that responds
        for gw in "${COMMON_GATEWAY_IPS[@]}"; do
            if ping -c $PING_COUNT -W $QUICK_TIMEOUT "$gw" >/dev/null 2>&1; then
                LOCAL_GATEWAY="$gw"
                break
            fi
        done
    fi
    
    # If no gateway found through any method, use a placeholder
    if [ -z "$LOCAL_GATEWAY" ]; then
        # For docker containers, sometimes we can't detect the gateway but internet still works
        LOCAL_GATEWAY="$DEFAULT_CONTAINER_GATEWAY"
    fi
}

# Test network interface using Alpine-specific methods
test_network_interface() {
    if [ "$MODE" != "is-online" ] && [ "$SILENT_MODE" != "true" ]; then
        printf "${BLUE}Network Interface Status${NC}\n"
    fi
    
    local primary_connection_found=false
    local interfaces_checked=0
    
    # Method 1: Use /sys/class/net (works in Alpine)
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
                # Get IP using ip command which is available in Alpine
                local ip=""
                if command -v ip >/dev/null 2>&1; then
                    # Use grep without -P which is not supported in BusyBox
                    ip=$(ip -4 addr show dev "$iface" 2>/dev/null | grep -o "inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | awk '{print $2}' | head -1)
                fi
                
                if [ -n "$ip" ]; then
                    local interface_type="Container"
                    case "$iface" in
                        eth*|en*|eno*|enp*) interface_type="Ethernet" ;;
                        wl*|wlan*) interface_type="WiFi" ;;
                        docker*|br-*|veth*) interface_type="Docker" ;;
                        *) interface_type="Network" ;;
                    esac
                    
                    log_status "SUCCESS" "$interface_type interface $iface" "IP: $ip, Status: up"
                    primary_connection_found=true
                fi
            fi
        done
    fi
    
    # Final check: Direct connectivity test as last resort
    if [ "$interfaces_checked" -eq 0 ] || [ "$primary_connection_found" = "false" ]; then
        # Quick connectivity check
        if curl -s --max-time $QUICK_TIMEOUT --connect-timeout $CONNECT_TIMEOUT -I "https://$QUICK_SITE" >/dev/null 2>&1; then
            log_status "SUCCESS" "Internet connectivity" "External access working (interface details unavailable)"
            primary_connection_found=true
        elif ping -c $PING_COUNT -W $QUICK_TIMEOUT $QUICK_DNS >/dev/null 2>&1; then
            log_status "SUCCESS" "Network connectivity" "Can reach external IP (interface details unavailable)"
            primary_connection_found=true
        fi
    fi
    
    if [ "$primary_connection_found" = "false" ]; then
        log_status "FAIL" "Network interfaces" "No active network interfaces with external connectivity found"
        return 1
    fi
    
    return 0
}
