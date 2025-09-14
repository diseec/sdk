#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ TEST FUNCTION REGISTRY                                                  ┃
# ┃ Manages test function registration, ordering, and "only" functionality ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Global variables for test registry
export TESTER_REGISTERED_FUNCTIONS=""
export TESTER_ONLY_FUNCTIONS=""
export TESTER_HAS_ONLY_FUNCTIONS=false
export TESTER_CURRENT_LINE_NUMBER=0

# Initialize test registry for a new test file
sdk_tester_registry_init() {
    TESTER_REGISTERED_FUNCTIONS=""
    TESTER_ONLY_FUNCTIONS=""
    TESTER_HAS_ONLY_FUNCTIONS=false
    TESTER_CURRENT_LINE_NUMBER=0
}

# Register a test function (called automatically when test functions are defined)
sdk_tester_registry_register() {
    local function_name="$1"
    local is_only="${2:-false}"
    
    # Add to registered functions list (maintains order)
    if [ -n "$TESTER_REGISTERED_FUNCTIONS" ]; then
        TESTER_REGISTERED_FUNCTIONS="$TESTER_REGISTERED_FUNCTIONS$function_name\n"
    else
        TESTER_REGISTERED_FUNCTIONS="$function_name\n"
    fi
    
    # If this is an "only" function, add to only list
    if [ "$is_only" = "true" ]; then
        TESTER_HAS_ONLY_FUNCTIONS=true
        if [ -n "$TESTER_ONLY_FUNCTIONS" ]; then
            TESTER_ONLY_FUNCTIONS="$TESTER_ONLY_FUNCTIONS$function_name\n"
        else
            TESTER_ONLY_FUNCTIONS="$function_name\n"
        fi
    fi
}

# Get test functions to run (respects "only" functionality and maintains order)
sdk_tester_registry_get_functions() {
    if [ "$TESTER_HAS_ONLY_FUNCTIONS" = "true" ]; then
        # If there are "only" functions, run only those
        echo -e "$TESTER_ONLY_FUNCTIONS" | grep -v '^$'
    else
        # Otherwise, run all registered functions in order
        echo -e "$TESTER_REGISTERED_FUNCTIONS" | grep -v '^$'
    fi
}

# Check if there are any registered test functions
sdk_tester_registry_has_functions() {
    [ -n "$TESTER_REGISTERED_FUNCTIONS" ]
}

# Check if there are "only" functions
sdk_tester_registry_has_only() {
    [ "$TESTER_HAS_ONLY_FUNCTIONS" = "true" ]
}

# Get count of functions to run
sdk_tester_registry_get_count() {
    local functions_to_run
    functions_to_run=$(sdk_tester_registry_get_functions)
    if [ -n "$functions_to_run" ]; then
        echo "$functions_to_run" | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Auto-register test functions based on their names
sdk_tester_auto_register_functions() {
    local test_file="$1"
    
    # Parse the test file to find function definitions in order
    if [ -f "$test_file" ]; then
        # Use awk to parse the file and find test function definitions in order
        local functions_in_order
        functions_in_order=$(awk '
            /^[[:space:]]*test_[a-zA-Z0-9_]*[[:space:]]*\([[:space:]]*\)[[:space:]]*\{/ {
                # Extract function name
                match($0, /test_[a-zA-Z0-9_]*/)
                func_name = substr($0, RSTART, RLENGTH)
                
                # Check if it is an "only" function
                is_only = "false"
                if (match(func_name, /_only$/)) {
                    is_only = "true"
                    # Remove _only suffix for actual function name
                    func_name = substr(func_name, 1, length(func_name) - 5)
                }
                
                print func_name ":" is_only
            }
        ' "$test_file")
        
        # Register functions in the order they appear
        if [ -n "$functions_in_order" ]; then
            echo "$functions_in_order" | while IFS=: read -r func_name is_only; do
                if [ -n "$func_name" ]; then
                    sdk_tester_registry_register "$func_name" "$is_only"
                fi
            done
        fi
    fi
}

# Alternative approach: scan declared functions and try to preserve order
sdk_tester_auto_register_declared_functions() {
    # Get all declared test functions
    local declared_functions
    declared_functions=$(declare -F | grep "declare -f test_" | sed 's/declare -f //')
    
    if [ -n "$declared_functions" ]; then
        echo "$declared_functions" | while IFS= read -r func_name; do
            if [ -n "$func_name" ]; then
                local is_only=false
                
                # Check if it's an "only" function
                if [[ "$func_name" == *"_only" ]]; then
                    is_only=true
                    # For _only functions, we want to keep the original name
                    # but register them as only functions
                fi
                
                sdk_tester_registry_register "$func_name" "$is_only"
            fi
        done
    fi
}
