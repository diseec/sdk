#!/bin/bash

# Internet connectivity checker CLI for Alpine container

c=$1; shift; case $c in
    iso|is-online)
        MODE="is-online"
        SILENT_MODE=true
        # Quick check for internet connectivity - returns 0 if online, 1 if offline
        quick_check
        return $?
        ;;
    tes|test)
        MODE="test"
        # Start with a header unless silent mode is enabled
        if [ "$SILENT_MODE" != "true" ]; then
            message 37 "⌁" "Quickly checking internet connectivity...\n"
        fi
        
        # Run basic connectivity test
        if quick_check; then
            overall_status=true
        else
            overall_status=false
        fi

        echo ""
        # Display a summary
        if [ "$SILENT_MODE" != "true" ]; then
            if [ "$overall_status" = "true" ]; then
                message 32 "⊕" "Internet connection working properly"
            else
                message 31 "⊘" "Internet connection has issues"
            fi
        fi
        
        # return with appropriate code
        [ "$overall_status" = "true" ] && return 0 || return 1
        ;;
    dia|diagnose)
        MODE="diagnose"
        message 37 "⚙" "Diagnosing internet connection ..."

        overall_status=true
        quick_check_success=false
        
        # Run comprehensive tests
        test_network_interface || overall_status=false
        
        # Run quick check first to see if we have basic internet connectivity
        if quick_check; then
            quick_check_success=true
        else
            quick_check_success=false
            overall_status=false
        fi
        
        # Special handling for DNS tests
        dns_result=0
        test_dns_servers
        dns_result=$?
        
        # Consider DNS failure as overall failure
        if [ $dns_result -ne 0 ]; then
            overall_status=false
        fi
        
        test_international_sites || overall_status=false
        test_regional_sites || overall_status=false
        test_cdn_connectivity || overall_status=false
        
        # Optional advanced tests
        # confirm "Run connection quality tests? (takes ~10 seconds)" test_connection_quality
        test_connection_quality
        
        # If something failed, run the diagnostic
        if [ "$overall_status" = "false" ]; then
            diagnose_connection_issues
        fi
        
        # Offer advanced diagnostics if still failing
        # if [ "$overall_status" = "false" ]; then
        #     confirm "Run advanced diagnostics? (takes ~15 seconds)" advanced_diagnostics
        # fi
        advanced_diagnostics
        
        echo ""
        # Display a summary
        if [ "$overall_status" = "true" ]; then
            message 32 "⊕" "Internet connection working properly"
        else
            message 31 "⊘" "Internet connection has issues"
        fi
        
        # return with appropriate code
        [ "$overall_status" = "true" ] && return 0 || return 1
        ;;
    -s|--silent)
        SILENT_MODE=true
        # Re-run the script with the silent flag
        cli_main internet_optimized "$@"
        return $?
        ;;
    hel|--help|help|-h) display_help "" "" \
            "$(color 37 'Internet Connection Checker (Optimized for Alpine)')" "" \
            "$(color 37 'Usage:    cli internet_optimized <mode> [options]\n')" "" \
            "$(color 37 'Modes:')" "" \
            "  iso|is-online         " "Silent boolean check - returns 0 for success, 1 for failure (no output)" \
            "  tes|test              " "Fast check with output - tests gateway, DNS, and one site (~2 seconds)" \
            "  dia|diagnose          " "Comprehensive analysis - tests all layers with detailed diagnostics (~30 seconds)" \
            "" "" "$(color 37 'Features:')" "" \
            "  • Docker-optimized implementation    " "Specifically designed for Alpine container environment" \
            "  • Iranian internet censorship detection " "Identifies filtering patterns and suggests solutions" \
            "  • Lightweight with minimal dependencies " "Uses only tools available in the base Docker image" \
            "  • Multi-layer connectivity testing   " "Gateway, DNS, HTTP(S), and CDN access verification" \
            "" "" "$(color 37 'Options:')" "" \
            "  -s|--silent           " "Suppress all output except errors" \
            "  -h|--help             " "Show this help message"
        exit 0
        ;;
    *)
        if [ ! -z $c ]; then message -e "Unknown command: '$c'"; fi
        cli_main internet_optimized help; exit 1;
        ;;
esac
