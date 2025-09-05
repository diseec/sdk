#!/bin/bash
# Test discovery functionality
# This script provides functions for finding and listing test files

# Function to find test files
find_test_files() {
    local search_dir="$1"
    local search_pattern="$2"
    
    if [ ! -d "$search_dir" ]; then
        log_warning "Directory '$search_dir' does not exist"
        return 1
    fi
    
    find "$search_dir" -name "$search_pattern" -type f 2>/dev/null | sort
}

# Function to list test files
list_test_files() {
    local test_dir="$1"
    local test_pattern="$2"
    local test_files
    
    test_files=$(find_test_files "$test_dir" "$test_pattern")
    
    if [ -z "$test_files" ]; then
        log_warning "No test files found in $test_dir matching pattern $test_pattern"
        return 0
    fi
    
    log_info "Available test files:"
    local count=0
    while read -r file; do
        if [ -n "$file" ]; then
            count=$((count + 1))
            # Show relative path from D_SDK_DIR
            local rel_path="${file#$D_SDK_DIR/}"
            echo -e "  ${COLOR_HIGHLIGHT}$count.${NC} $rel_path"
        fi
    done <<< "$test_files"
    
    echo -e "\n${COLOR_INFO}Total: $count test file(s)${NC}"
}

# Function to get test metadata
get_test_metadata() {
    local test_file="$1"
    
    if [ ! -f "$test_file" ]; then
        log_error "Test file '$test_file' not found"
        return 1
    fi
    
    # Extract test name and description from file header
    local test_name=$(basename "$test_file")
    local test_description=$(grep -E "^#.*" "$test_file" | head -1 | sed 's/^#\s*//')
    
    echo "Name: $test_name"
    echo "Description: $test_description"
    echo "Path: $test_file"
}
