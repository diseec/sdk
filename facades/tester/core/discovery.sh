#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST DISCOVERY ENGINE                                                   ┃
# ┃ Automatically finds and filters test files across the project          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Discover all test files in the project
sdk_tester_discover_all_tests() {
    local search_root="${D_CTX_DIR:-$(pwd)}"
    
    # Find all *.test.sh files recursively
    find "$search_root" -type f -name "*.test.sh" 2>/dev/null | sort
}

# Filter test files by pattern
sdk_tester_filter_tests() {
    local pattern="$1"
    local all_tests="$2"
    
    if [ -z "$pattern" ]; then
        echo "$all_tests"
        return 0
    fi
    
    # Filter tests that contain the pattern in filename or path
    echo "$all_tests" | grep -i "$pattern"
}

# Discover and show test discovery information
sdk_tester_discover_tests() {
    local pattern="${1:-}"
    local show_stats="${2:-true}"
    
    stdout -i "$(ansi $TESTER_COLOR_HEADER "DISCOVERING TESTS")"
    stdout --ansi="$TESTER_COLOR_DIM" "Search root: $(ansi 97 "${D_CTX_DIR:-$(pwd)}")"
    
    if [ -n "$pattern" ]; then
        stdout --ansi="$TESTER_COLOR_DIM" "Filter pattern: $(ansi 97 "$pattern")"
    fi
    
    local all_tests
    all_tests=$(sdk_tester_discover_all_tests)
    
    if [ -z "$all_tests" ]; then
        stdout -w "No test files found matching pattern '*.test.sh'"
        return 1
    fi
    
    local filtered_tests
    filtered_tests=$(sdk_tester_filter_tests "$pattern" "$all_tests")
    
    if [ -z "$filtered_tests" ]; then
        stdout -w "No test files found matching pattern: $pattern"
        return 1
    fi
    
    local test_count
    test_count=$(echo "$filtered_tests" | wc -l | tr -d ' ')
    
    if [ "$show_stats" = "true" ]; then
        echo ""
        stdout -i "$(ansi $TESTER_COLOR_INFO "Found $test_count test file(s):")"
        echo ""
    fi
    
    # Display found tests with relative paths
    local search_root="${D_CTX_DIR:-$(pwd)}"
    echo "$filtered_tests" | while IFS= read -r test_file; do
        if [ -n "$test_file" ]; then
            local relative_path="${test_file#$search_root/}"
            if [ "$show_stats" = "true" ]; then
                stdout --ansi="$TESTER_COLOR_DIM" "  $(ansi 97 "$relative_path")"
            else
                echo "$test_file"
            fi
        fi
    done
    
    if [ "$show_stats" = "true" ]; then
        echo ""
    fi
    
    return 0
}

# List all discoverable tests
sdk_tester_list_tests() {
    local pattern="${1:-}"
    
    # Discover and display tests
    sdk_tester_discover_tests "$pattern" "true"
}

# Calculate test coverage statistics
sdk_tester_calculate_coverage() {
    local search_root="${D_CTX_DIR:-$(pwd)}"
    
    # Create temporary files to store results
    local temp_sh_files=$(mktemp)
    local temp_test_files=$(mktemp)
    
    # Find all non-test .sh files and test files
    find "$search_root" -type f -name "*.sh" ! -name "*.test.sh" 2>/dev/null | sort > "$temp_sh_files"
    find "$search_root" -type f -name "*.test.sh" 2>/dev/null | sort > "$temp_test_files"
    
    # Count files
    local total_sh_files=$(grep -c "." "$temp_sh_files" || echo 0)
    local total_test_files=$(grep -c "." "$temp_test_files" || echo 0)
    
    # Count covered files (both ways)
    local covered_files=0
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local test_file="${file%.sh}.test.sh"
            if [ -f "$test_file" ]; then
                covered_files=$((covered_files + 1))
            fi
        fi
    done < "$temp_sh_files"
    
    local orphaned_tests=0
    while IFS= read -r test_file; do
        if [ -n "$test_file" ]; then
            local source_file="${test_file%.test.sh}.sh"
            if [ ! -f "$source_file" ]; then
                orphaned_tests=$((orphaned_tests + 1))
            fi
        fi
    done < "$temp_test_files"
    
    # Calculate coverage percentage based on total files that should have tests
    local total_files=$((total_sh_files + orphaned_tests))
    local coverage_percent=0
    if [ $total_files -gt 0 ]; then
        coverage_percent=$(( (covered_files + orphaned_tests) * 100 / total_files ))
    fi
    
    # Cleanup temp files
    rm -f "$temp_sh_files" "$temp_test_files"
    
    # Return coverage stats with additional orphaned test count
    echo "$coverage_percent:$((covered_files + orphaned_tests)):$total_files:$orphaned_tests"
}

# Get test files for running (internal function)
_sdk_tester_get_test_files() {
    local pattern="${1:-}"
    
    local all_tests
    all_tests=$(sdk_tester_discover_all_tests)
    
    if [ -z "$all_tests" ]; then
        return 1
    fi
    
    sdk_tester_filter_tests "$pattern" "$all_tests"
}
