#!/bin/bash

# Main entry point for the internet connectivity checker

# Source all required modules
. $KIT_SRC_DIR/utils/internet/os_detection.sh
. $KIT_SRC_DIR/utils/internet/math_utils.sh
. $KIT_SRC_DIR/utils/internet/config.sh
. $KIT_SRC_DIR/utils/internet/logging.sh
. $KIT_SRC_DIR/utils/internet/args.sh
. $KIT_SRC_DIR/utils/internet/network.sh
. $KIT_SRC_DIR/utils/internet/basic_tests.sh
. $KIT_SRC_DIR/utils/internet/dns_tests.sh
. $KIT_SRC_DIR/utils/internet/site_tests.sh
. $KIT_SRC_DIR/utils/internet/quality_tests.sh
. $KIT_SRC_DIR/utils/internet/diagnosis.sh

# Main execution
main() {
    parse_args "$@"
    
    local overall_status=""
    
    case "$MODE" in
        test)
            if [ "$SILENT_MODE" != "true" ]; then
                message 43 ↔ "Quick internet connectivity check"
            fi
            if quick_check; then
                overall_status=true
            else
                overall_status=false
            fi
            ;;
            
        is-online)
            # Silent boolean check - no start message
            if quick_check; then
                overall_status=true
            else
                overall_status=false
            fi
            ;;
            
        diagnose)
            message 44 "Full internet connection diagnostic"
            
            overall_status=true
            # Always include connection quality in diagnose mode, no need for separate debug flag
            test_network_interface || overall_status=false
            quick_check || overall_status=false
            test_dns_servers || overall_status=false
            test_international_sites || overall_status=false
            test_regional_sites || overall_status=false
            test_cdn_connectivity || overall_status=false
            ask_to_run_command "Run stability tests? (~30sec)" test_connection_quality
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
                diagnose_connection_issues
            fi
        else
            printf "${RED}[ERROR]${NC} Incomplete operation, Script execution failed.\n"
        fi
    fi
    
    # Exit with appropriate code
    [ "$overall_status" = "true" ] && exit 0 || exit 1
}

# Run the script
main "$@"
