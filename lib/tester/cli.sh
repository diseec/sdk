#!/bin/bash

# CLI interface for the e2e testing framework
# This script handles command routing for the testing framework

# Source the main testing framework
source_once "$D_SDK_DIR/lib/tester/index.sh"

if [ $# -eq 0 ]; then set -- run; fi

# Command router for testing framework
c=$1; shift; case $c in
    run)
        # Run tests
        local filter="" summary_only=0 safely_flag=0 specific_tests=()
        
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --filter=*)
                    filter="${1#*=}"
                    shift
                    ;;
                --summary-only)
                    summary_only=1
                    shift
                    ;;
                --safely)
                    safely_flag=1
                    shift
                    ;;
                *)
                    specific_tests+=("$1")
                    shift
                    ;;
            esac
        done
        
        if [[ $safely_flag -eq 1 ]]; then
            safely sdk_lib_tester_run "${specific_tests[@]}" --filter="$filter" $([ $summary_only -eq 1 ] && echo "--summary-only")
        else
            sdk_lib_tester_run "${specific_tests[@]}" --filter="$filter" $([ $summary_only -eq 1 ] && echo "--summary-only")
        fi
        ;;
    list)
        # List all available tests
        local filter=""
        
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --filter=*)
                    filter="${1#*=}"
                    shift
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        
        tests=($(sdk_lib_tester_utils_discover_tests))
        
        # Filter tests if requested
        if [[ -n "$filter" ]]; then
            local filtered_tests=()
            for test_file in "${tests[@]}"; do
                if [[ "$test_file" == *"$filter"* ]]; then
                    filtered_tests+=("$test_file")
                fi
            done
            tests=("${filtered_tests[@]}")
        fi
        
        logit -i "Found ${#tests[@]} test files"
        
        for test in "${tests[@]}"; do
            local relative_path="${test#$D_CTX_DIR/}"
            local test_name=$(sdk_lib_tester_utils_get_test_name "$test")
            logit -s "$(ansi "2;90" "$relative_path") $(ansi "1;97" "$test_name")"
        done
        ;;
    setup)
        # Setup test project environment
        local project_name="" template=""
        
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --name=*)
                    project_name="${1#*=}"
                    shift
                    ;;
                --template=*)
                    template="${1#*=}"
                    shift
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        
        if [[ -z "$project_name" ]]; then
            logit -e "Project name is required (--name=your-project-name)"
            return 1
        fi
        
        sdk_lib_tester_setup_project "$project_name" "$template"
        ;;
    assert)
        # Run a specific assertion (useful for debugging)
        local function_name="$1"
        shift
        
        if [[ -z "$function_name" ]]; then
            logit -e "Assertion function name is required"
            return 1
        fi
        
        if [[ "$(type -t "$function_name")" != "function" ]]; then
            logit -e "Assertion function '$function_name' not found"
            return 1
        fi
        
        "$function_name" "$@"
        ;;
    hel|help|--help|-h)
        display_help "" "" \
            "$(ansi "1;90" "$(capitalize 'Usage')")                        " "[$D_CLI_GLOBAL_NAME test]/[bash $D_CLI_LOCAL_NAME test] [command] [options]" \
            "                             " "$(ansi "2;90" "E2E Testing Framework for SDK")" \
            "" "" \
            "$(ansi "1;90" "$(capitalize 'Commands')")" "" \
            "    run                   " "Run tests" \
            "        --filter=<term>   " "$(ansi "2;90" "Filter tests by name or path")" \
            "        --summary-only    " "$(ansi "2;90" "Only show test summary, not individual test results")" \
            "        --safely          " "$(ansi "2;90" "Run tests in SDK container for consistent environment")" \
            "        <test-files...>   " "$(ansi "2;90" "Specific test files to run (optional)")" \
            "    list                  " "List all available tests" \
            "        --filter=<term>   " "$(ansi "2;90" "Filter tests by name or path")" \
            "    setup                 " "Set up a test project environment" \
            "        --name=<name>     " "$(ansi "2;90" "Name of the test project (required)")" \
            "        --template=<tpl>  " "$(ansi "2;90" "Template to use (optional)")" \
            "    assert                " "Run a specific assertion (for debugging)" \
            "        <function-name>   " "$(ansi "2;90" "Name of the assertion function to run")" \
            "        <args...>         " "$(ansi "2;90" "Arguments to pass to the assertion function")" \
            "" "" \
            "$(ansi "1;90" "$(capitalize 'Examples')")" "" \
            "    $D_CLI_GLOBAL_NAME test run                      " "$(ansi "2;90" "Run all tests")" \
            "    $D_CLI_GLOBAL_NAME test run --filter=git         " "$(ansi "2;90" "Run all tests containing 'git' in their path")" \
            "    $D_CLI_GLOBAL_NAME test run --safely             " "$(ansi "2;90" "Run tests in SDK container")" \
            "    $D_CLI_GLOBAL_NAME test list                     " "$(ansi "2;90" "List all available tests")" \
            "    $D_CLI_GLOBAL_NAME test setup --name=my-test     " "$(ansi "2;90" "Set up a test project")" \
            "$@"
        ;;
    *)
        if [[ -n "$c" ]]; then 
            logit -e "Unknown command: '$c'"
        fi
        cli_ctx sdk test help
        return 1
        ;;
esac
