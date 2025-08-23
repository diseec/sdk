#!/bin/bash

# Connection issue diagnosis and failure analysis

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
