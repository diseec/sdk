#!/bin/bash

# OS detection and command compatibility utilities

# Detect operating system
fac_int_detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "freebsd"
    else
        # Try to detect from system files
        if [ -f /etc/os-release ]; then
            echo "linux"
        elif [ -f /etc/debian_version ]; then
            echo "linux"
        elif [ -f /etc/alpine-release ]; then
            echo "linux"
        else
            echo "unknown"
        fi
    fi
}

# Get compatible ping command with timeout options
fac_int_get_ping_command() {
    local timeout=${1:-5}
    local os=$(fac_int_detect_os)
    
    case "$os" in
        macos)
            if ping -t "$timeout" -c 1 127.0.0.1 >/dev/null 2>&1; then
                echo "ping -t $timeout"
            else
                echo "ping"
            fi
            ;;
        linux)
            if command -v timeout >/dev/null 2>&1 && ping -W "$timeout" -c 1 127.0.0.1 >/dev/null 2>&1; then
                echo "timeout ${timeout}s ping -W $timeout"
            elif ping -W "$timeout" -c 1 127.0.0.1 >/dev/null 2>&1; then
                echo "ping -W $timeout"
            else
                echo "ping"
            fi
            ;;
        *)
            echo "ping"
            ;;
    esac
}

# Get compatible network interface listing command
fac_int_get_interface_command() {
    local os=$(fac_int_detect_os)
    
    case "$os" in
        linux)
            if command -v ip >/dev/null 2>&1; then
                echo "ip"
            elif command -v ifconfig >/dev/null 2>&1; then
                echo "ifconfig"
            else
                echo "none"
            fi
            ;;
        macos)
            if command -v ifconfig >/dev/null 2>&1; then
                echo "ifconfig"
            else
                echo "none"
            fi
            ;;
        *)
            echo "none"
            ;;
    esac
}

# Get compatible route command
fac_int_get_route_command() {
    local os=$(fac_int_detect_os)
    
    case "$os" in
        linux)
            if command -v ip >/dev/null 2>&1; then
                echo "ip route show default"
            elif command -v netstat >/dev/null 2>&1; then
                echo "netstat -rn"
            else
                echo "none"
            fi
            ;;
        macos)
            if command -v route >/dev/null 2>&1; then
                echo "route -n get default"
            elif command -v netstat >/dev/null 2>&1; then
                echo "netstat -rn"
            else
                echo "none"
            fi
            ;;
        *)
            echo "none"
            ;;
    esac
}

# Get compatible DNS lookup command
fac_int_get_dns_command() {
    if command -v nslookup >/dev/null 2>&1; then
        echo "nslookup"
    elif command -v dig >/dev/null 2>&1; then
        echo "dig"
    elif command -v host >/dev/null 2>&1; then
        echo "host"
    else
        echo "none"
    fi
}

# Test if a command exists with proper options
fac_int_test_command_compatibility() {
    local cmd="$1"
    local test_args="$2"
    
    eval "$cmd $test_args" >/dev/null 2>&1
    return $?
}

# Export functions for use in other modules
export -f fac_int_detect_os
export -f fac_int_get_ping_command
export -f fac_int_get_interface_command
export -f fac_int_get_route_command
export -f fac_int_get_dns_command
export -f fac_int_test_command_compatibility
