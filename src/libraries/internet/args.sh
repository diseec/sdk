#!/bin/bash

# Command line argument parsing and help functions

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            dia|--diagnose|diagnose)
                MODE="diagnose"
                shift
                ;;
            tes|--test|test)
                MODE="test"
                shift
                ;;
            iso|--is-online|is-online)
                MODE="is-online"
                SILENT_MODE=true
                shift
                ;;
            --silent|silent)
                SILENT_MODE=true
                shift
                ;;
            --help|help|-h)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

show_help() {
    echo "Internet Connection Checker with Advanced Diagnostics"
    echo "===================================================="
    echo ""
    echo "Usage: $0 [mode] [options]"
    echo ""
    echo "Modes:"
    echo "  dia|diagnose    - Comprehensive analysis - tests all layers, sites, velocity, and disconnections (~45 seconds)"
    echo "  iso|is-online   - Silent boolean check - returns 0 for success, 1 for failure (no output)"
    echo "  tes|test        - Fast check with output - tests gateway, DNS, and one site (~3 seconds)"
    echo ""
    echo "Advanced Features (diagnose mode):"
    echo "  • Velocity analysis - measures request/response speed with variance detection"
    echo "  • Random disconnection testing - detects intermittent connection drops"
    echo "  • Speed consistency analysis - identifies throttling and congestion patterns"
    echo "  • Multi-round throughput testing - comprehensive bandwidth measurement"
    echo "  • Connection quality scoring - combines speed, stability, and consistency metrics"
    echo ""
    echo "Options:"
    echo "  --silent - Suppress all output except errors"
    echo "  --help  - Show this help message"
}
