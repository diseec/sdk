#!/bin/bash

# Network utility functions for internet connectivity checker

# Get default gateway
get_gateway() {
    # Try modern Linux ip command first
    if command -v ip >/dev/null 2>&1; then
        LOCAL_GATEWAY=$(ip route show default 2>/dev/null | awk '{print $3}' | head -1)
    fi
    
    # Fallback to macOS route command
    if [ -z "$LOCAL_GATEWAY" ] && command -v route >/dev/null 2>&1; then
        LOCAL_GATEWAY=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}' | head -1)
    fi
    
    # Fallback to netstat (older systems)
    if [ -z "$LOCAL_GATEWAY" ] && command -v netstat >/dev/null 2>&1; then
        LOCAL_GATEWAY=$(netstat -rn | grep default | awk '{print $2}' | head -1)
    fi
}

# Test network interface
test_network_interface() {
    if [ "$MODE" != "test" ]; then
        printf "${BLUE}Network Interface Status${NC}\n"
    fi
    
    local wifi_interfaces=""
    local ethernet_interfaces=""
    local vpn_interfaces=""
    
    # Detect OS and use appropriate commands
    if command -v ip >/dev/null 2>&1; then
        # Modern Linux with ip command
        wifi_interfaces=$(ip link show | grep -E "^[0-9]+: (wl|wlan)[0-9]+" | grep "state UP" | cut -d: -f2 | tr -d ' ')
        ethernet_interfaces=$(ip link show | grep -E "^[0-9]+: (eth|en|eno|enp)[0-9]+" | grep "state UP" | cut -d: -f2 | tr -d ' ')
        vpn_interfaces=$(ip link show | grep -E "^[0-9]+: (tun|tap|ppp)[0-9]+" | grep "state UP" | cut -d: -f2 | tr -d ' ')
        
        # Check for Docker container environment by looking for typical container interfaces
        if [ -f "/.dockerenv" ] || [ -n "$(ip link show | grep "^[0-9]*: eth0:")" ]; then
            # In a container, treat eth0 as a valid network interface
            container_interfaces=$(ip link show | grep -E "^[0-9]+: eth[0-9]+" | grep "state UP" | cut -d: -f2 | tr -d ' ')
            ethernet_interfaces="$ethernet_interfaces $container_interfaces"
        fi
    elif command -v ifconfig >/dev/null 2>&1; then
        # macOS or systems with ifconfig
        wifi_interfaces=$(ifconfig | grep -E "^(en[0-9]+|wl[0-9]+)" | grep -E "flags=.*<UP,.*RUNNING" | cut -d: -f1)
        ethernet_interfaces=$(ifconfig | grep -E "^(en[0-9]+)" | grep -E "flags=.*<UP,.*RUNNING" | cut -d: -f1)
        vpn_interfaces=$(ifconfig | grep -E "^(utun|tun|ppp)" | grep -E "flags=.*<UP,.*RUNNING" | cut -d: -f1)
    else
        # Fallback: try to read from /sys (Linux)
        if [ -d "/sys/class/net" ]; then
            for iface in /sys/class/net/*; do
                local name=$(basename "$iface")
                if [ -f "$iface/operstate" ] && [ "$(cat "$iface/operstate")" = "up" ]; then
                    case "$name" in
                        wl*|wlan*) wifi_interfaces="$wifi_interfaces $name" ;;
                        eth*|en*|eno*|enp*) ethernet_interfaces="$ethernet_interfaces $name" ;;
                        tun*|tap*|ppp*) vpn_interfaces="$vpn_interfaces $name" ;;
                    esac
                fi
            done
        fi
    fi
    
    local primary_connection_found=false
    
    # Check WiFi/Ethernet first (primary connections)
    if [ -n "$wifi_interfaces" ] || [ -n "$ethernet_interfaces" ]; then
        for interface in $wifi_interfaces $ethernet_interfaces; do
            local ip=""
            local status=""
            
            # Get IP address using appropriate method
            if command -v ip >/dev/null 2>&1; then
                ip=$(ip addr show "$interface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -1)
                status=$(ip link show "$interface" 2>/dev/null | grep "state" | awk '{print $9}')
            elif command -v ifconfig >/dev/null 2>&1; then
                ip=$(ifconfig "$interface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
                status=$(ifconfig "$interface" 2>/dev/null | grep "status:" | awk '{print $2}' | head -1)
            fi
            
            if [ -n "$ip" ]; then
                local interface_type="Ethernet"
                if echo "$interface" | grep -qE "^(wl|wlan)"; then
                    interface_type="WiFi"
                elif echo "$interface" | grep -q "en[0-9]"; then
                    # Check if this en interface is WiFi by looking for WiFi-specific info
                    if command -v ifconfig >/dev/null 2>&1 && ifconfig "$interface" 2>/dev/null | grep -q "SSID\|AirPort"; then
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
            local ip=""
            
            # Get IP address using appropriate method
            if command -v ip >/dev/null 2>&1; then
                ip=$(ip addr show "$interface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -1)
            elif command -v ifconfig >/dev/null 2>&1; then
                ip=$(ifconfig "$interface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
            fi
            
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
