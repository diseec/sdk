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
