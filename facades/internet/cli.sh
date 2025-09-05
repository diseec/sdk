#!/bin/bash

source_once "$D_SDK_DIR/facades/internet/index.sh"

# Internet connectivity checker CLI for Alpine container

c=$1; shift; case $c in
    iso|is-online)
        MODE="is-online"
        SILENT_MODE=true
        # Quick check for internet connectivity - returns 0 if online, 1 if offline
        src_fac_int_quick_check
        return $?
        ;;
    tes|test)
        MODE="test"
        # Start with a header unless silent mode is enabled
        if [ "$SILENT_MODE" != "true" ]; then
            logit --ansi="97" --icon="⌁" "Quick internet connectivity check...\n"
        fi
        
        # Run basic connectivity test
        if src_fac_int_quick_check; then
            overall_status=true
        else
            overall_status=false
        fi

        echo ""
        # Display a summary
        if [ "$SILENT_MODE" != "true" ]; then
            if [ "$overall_status" = "true" ]; then
                logit --ansi="32" --icon="⊕" "Internet connection working properly"
            else
                logit --ansi="31" --icon="⊘" "Internet connection has issues"
            fi
        fi
        
        # return with appropriate code
        [ "$overall_status" = "true" ] && return 0 || return 1
        ;;
    dia|diagnose)
        MODE="diagnose"
        SILENT_MODE=false
        logit --ansi="97" --icon="⚙" "Diagnosing internet connection ..."

        overall_status=true
        quick_check_success=false
        
        # Run comprehensive tests
        src_fac_int_test_network_interface || overall_status=false
        
        # Run quick check first to see if we have basic internet connectivity
        if src_fac_int_quick_check; then
            quick_check_success=true
        else
            quick_check_success=false
            overall_status=false
        fi
        
        # Special handling for DNS tests
        dns_result=0
        src_fac_int_test_dns_servers
        dns_result=$?
        
        # Consider DNS failure as overall failure
        if [ $dns_result -ne 0 ]; then
            overall_status=false
        fi
        
        src_fac_int_test_international_sites || overall_status=false
        src_fac_int_test_regional_sites || overall_status=false
        src_fac_int_test_cdn_connectivity || overall_status=false
        
        # Optional advanced tests
        # confirm "Run connection quality tests? (takes ~10 seconds)" src_fac_int_test_connection_quality
        src_fac_int_test_connection_quality
        
        # If something failed, run the diagnostic
        if [ "$overall_status" = "false" ]; then
            src_fac_int_diagnose_connection_issues
        fi
        
        # Offer advanced diagnostics if still failing
        # if [ "$overall_status" = "false" ]; then
        #     confirm "Run advanced diagnostics? (takes ~15 seconds)" src_fac_int_advanced_diagnostics
        # fi
        src_fac_int_advanced_diagnostics
        
        echo ""
        # Display a summary
        if [ "$overall_status" = "true" ]; then
            logit --ansi="32" --icon="⊕" "Internet connection working properly"
        else
            logit --ansi="31" --icon="⊘" "Internet connection has issues"
        fi
        
        # return with appropriate code
        [ "$overall_status" = "true" ] && return 0 || return 1
        ;;
    -s|--silent)
        SILENT_MODE=true
        # Re-run the script with the silent flag
        cli_main internet "$@"
        return $?
        ;;
        x) echo dsaf;;
    hel|--help|help|-h) display_help "" "" \
            "$(ansi 97 'Internet Connection Checker (Optimized for Alpine)')" "" \
            "$(ansi 97 'Usage:    cli internet <mode> [options]')" "" "" "" \
            "$(ansi 97 'Modes:')" "" \
            "  iso|is-online         " "Silent boolean check - returns 0 for success, 1 for failure (no output)" \
            "  tes|test              " "Fast check with output - tests gateway, DNS, and one site (~2 seconds)" \
            "  dia|diagnose          " "Comprehensive analysis - tests all layers with detailed diagnostics (~30 seconds)" \
            "" "" "$(ansi 97 'Features:')" "" \
            "  • Docker-optimized implementation    " "Specifically designed for Alpine container environment" \
            "  • Iranian internet censorship detection " "Identifies filtering patterns and suggests solutions" \
            "  • Lightweight with minimal dependencies " "Uses only tools available in the base Docker image" \
            "  • Multi-layer connectivity testing   " "Gateway, DNS, HTTP(S), and CDN access verification" \
            "" "" "$(ansi 97 'Options:')" "" \
            "  -s|--silent           " "Suppress all output except errors" \
            "  -h|--help             " "Show this help message"
        exit 0
        ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then logit -e "Unknown command: '$c'"; fi
        cli_main internet help; exit 1;
        ;;
esac
