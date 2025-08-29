#!/bin/bash

fac_int_parse_args "$@"

local overall_status=""

case "$MODE" in
    test)
        if [ "$SILENT_MODE" != "true" ]; then
            message 43 ↔ "Quick internet connectivity check"
        fi
        if fac_int_quick_check; then
            overall_status=true
        else
            overall_status=false
        fi
        ;;
        
    is-online)
        # Silent boolean check - no start message
        if fac_int_quick_check; then
            overall_status=true
        else
            overall_status=false
        fi
        ;;
        
    diagnose)
        message 44 "Full internet connection diagnostic"
        
        overall_status=true
        # Always include connection quality in diagnose mode, no need for separate debug flag
        fac_int_test_network_interface || overall_status=false
        fac_int_quick_check || overall_status=false
        fac_int_test_dns_servers || overall_status=false
        fac_int_test_international_sites || overall_status=false
        fac_int_test_regional_sites || overall_status=false
        fac_int_test_cdn_connectivity || overall_status=false
        confirm "Run stability tests? ~30 seconds" fac_int_test_connection_quality
        ;;
esac

# Summary (except in check mode)
if [ "$MODE" != "is-online" ] && [ "$SILENT_MODE" != "true" ]; then
    if [ "$overall_status" = "true" ]; then
        printf "${GREEN}[SUCCESS]${NC} Internet connection working properly\n"
    elif [ "$overall_status" = "false" ]; then
        printf "${RED}[FAILED]${NC} Internet connection has issues\n"
        # Run intelligent diagnosis if we have test results
        if [ "$MODE" = "diagnose" ]; then
            fac_int_diagnose_connection_issues
        fi
    else
        printf "${RED}[ERROR]${NC} Incomplete operation, Script execution failed.\n"
    fi
fi

# Exit with appropriate code
[ "$overall_status" = "true" ] && exit 0 || exit 1
