#!/bin/bash

# Configuration for optimized internet connectivity checker

# ====================================
# Timeout settings (in seconds)
# ====================================
QUICK_TIMEOUT=1                   # Timeout for basic connectivity tests
FULL_TIMEOUT=2                    # Timeout for more comprehensive tests
CONNECT_TIMEOUT=2                 # Connection timeout for HTTP requests
DNS_LOOKUP_TIMEOUT=2              # Timeout for DNS lookups
PING_COUNT=1                      # Number of pings to send in basic tests
LATENCY_PING_COUNT=4              # Number of pings for latency testing
TRACEROUTE_TIMEOUT=5              # Timeout for traceroute commands
TRACEROUTE_MAX_HOPS=10            # Maximum number of hops for traceroute
PUBLIC_IP_TIMEOUT=3               # Timeout for public IP lookup

# ====================================
# Test targets
# ====================================
# DNS servers
PRIMARY_DNS_SERVER="8.8.8.8"      # Primary DNS server
SECONDARY_DNS_SERVER="1.1.1.1"    # Secondary DNS server
DNS_SERVERS=("$PRIMARY_DNS_SERVER" "$SECONDARY_DNS_SERVER") # DNS servers to test
DNS_PING_TIMEOUT=1                # Timeout for DNS ping tests
DNS_RESOLUTION_TIMEOUT=2          # Timeout for DNS resolution tests

# Primary test sites
QUICK_DNS="$PRIMARY_DNS_SERVER"   # DNS server for quick tests
QUICK_SITE="diseec.com"           # Site for quick connectivity check
ALTERNATIVE_QUICK_SITE="github.com" # Alternative site for quick checks
DNS_TEST_DOMAIN="github.com"      # Domain used for DNS resolution tests

# International sites to test
INTERNATIONAL_SITES=(
  "github.com"
  "cloudflare.com"
)

# Regional sites (Iran) to test
REGIONAL_SITES=(
  "khamenei.ir"
  "aparat.com"
)

# CDN sites to test
CDN_SITES=(
  "cdn.jsdelivr.net"
  "cdnjs.cloudflare.com"
)

# Sites for censorship testing
CENSORSHIP_TEST_SITE1="www.diseec.com"
CENSORSHIP_TEST_SITE2="www.google.com"
CENSORSHIP_TEST_SITE3="hub.docker.com"
CENSORSHIP_TEST_SITES=(
  "$CENSORSHIP_TEST_SITE1"
  "$CENSORSHIP_TEST_SITE2"
  "$CENSORSHIP_TEST_SITE3"
)

# Sites for local (Iranian) services testing
LOCAL_TEST_SITE="khamenei.ir"
LOCAL_TEST_SITE2="www.aparat.com"
LOCAL_SERVICES=(
  "$LOCAL_TEST_SITE"
  "$LOCAL_TEST_SITE2"
)

# Public IP lookup services
IP_CHECK_SERVICE1="ifconfig.me"
IP_CHECK_SERVICE2="api.ipify.org"
PUBLIC_IP_SERVICES=(
  "$IP_CHECK_SERVICE1"
  "$IP_CHECK_SERVICE2"
)
PROXY_CHECK_TIMEOUT=2            # Timeout for proxy detection checks

# ====================================
# Network settings
# ====================================
# Common gateway IPs for container environments
COMMON_GATEWAY_IPS=(
  "172.17.0.1"  # Default Docker gateway
  "192.168.1.1"
  "192.168.0.1"
  "10.0.0.1"
  "172.16.0.1"
)

# SSL/TLS and Traceroute testing
SSL_CHECK_SITE="www.google.com"  # Site for SSL/TLS validation
TRACE_TARGET="diseec.com"        # Target for traceroute tests
SITE_HTTPS_TIMEOUT=2             # Timeout for HTTPS site tests
SITE_PING_TIMEOUT=2              # Timeout for site ping tests

DEFAULT_CONTAINER_GATEWAY="172.17.0.1"  # Fallback gateway for containers

# Performance thresholds
GOOD_MTU=1400                    # Standard MTU size in bytes is 1500
GOOD_LATENCY_THRESHOLD=150       # Good latency threshold in ms best is <100ms
MODERATE_LATENCY_THRESHOLD=250   # Moderate latency threshold in ms best is <200ms
ACCEPTABLE_PACKET_LOSS=5         # Minor packet loss threshold in %
GOOD_SPEED_THRESHOLD=6           # Good download speed threshold in Mbps
MODERATE_SPEED_THRESHOLD=3       # Moderate download speed threshold in Mbps
LATENCY_TEST_SITE="diseec.com"   # Site for latency testing
LATENCY_TEST_COUNT=4             # Number of pings for latency testing
LATENCY_TIMEOUT=2                # Timeout for latency test pings

# Speed test settings
SPEED_TEST_FILE_SIZE=1048576      # 1MB in bytes
SPEED_TEST_URL="https://speed.cloudflare.com/__down?bytes=1048576"

# ====================================
# Appearance settings
# ====================================
# Colors for status messages
WHITE_FILLED_BOLD='\033[1;47m'
WHITE_FILLED='\033[0;47m'
GRAY='\033[0;90m'
WHITE='\033[0;97m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# ====================================
# Global variables to track test results
# ====================================
LOCAL_GATEWAY=""
GATEWAY_STATUS=""
DNS_STATUS=""
HTTP_STATUS=""

# ====================================
# Mode settings
# ====================================
MODE="test"
SILENT_MODE=false

# ====================================
# Utility functions
# ====================================
# Log a status message with color-coding
src_fac_int_log_status() {
    local status="$1"
    local test_name="$2"
    local details="$3"
    local timing="${4:-}"
    
    # Only output if not in silent mode
    if [ "$SILENT_MODE" != "true" ]; then
        case "$status" in
            SUCCESS)
                printf "${GRAY}[✓]${GRAY} %-25s %s ${WHITE}%s${NC}\n" "$test_name" "$details" "$timing"
                ;;
            FAIL)
                printf "${RED}[✖]${GRAY} %-25s %s ${WHITE}%s${NC}\n" "$test_name" "$details" "$timing"
                ;;
            WARNING)
                printf "${YELLOW}[!]${GRAY} %-25s %s ${WHITE}%s${NC}\n" "$test_name" "$details" "$timing"
                ;;
            INFO)
                printf "${GRAY}[i]${GRAY} %-25s %s ${WHITE}%s${NC}\n" "$test_name" "$details" "$timing"
                ;;
        esac
    fi
}

# Calculate duration between two timestamps
src_fac_int_calculate_duration() {
    local start="$1"
    local end="$2"
    
    # Use bc if available for better precision
    if command -v bc >/dev/null 2>&1; then
        echo $(echo "$end - $start" | bc | awk '{printf "%.2f", $0}')
    else
        # Fallback to less precise calculation
        echo $(echo "$end - $start" | awk '{printf "%.2f", $0}')
    fi
}
