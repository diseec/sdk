#!/bin/bash

# Math utilities that work without bc dependency

# Calculate time difference using awk (more portable than bc)
fac_int_calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    # Use awk for floating point arithmetic - available on all systems
    echo "$start_time $end_time" | awk '{printf "%.6f", $2 - $1}'
}

# Compare floating point numbers using awk
fac_int_float_compare() {
    local num1="$1"
    local operator="$2"
    local num2="$3"
    
    case "$operator" in
        ">")
            echo "$num1 $num2" | awk '{if($1 > $2) print "1"; else print "0"}'
            ;;
        "<")
            echo "$num1 $num2" | awk '{if($1 < $2) print "1"; else print "0"}'
            ;;
        ">=")
            echo "$num1 $num2" | awk '{if($1 >= $2) print "1"; else print "0"}'
            ;;
        "<=")
            echo "$num1 $num2" | awk '{if($1 <= $2) print "1"; else print "0"}'
            ;;
        "==")
            echo "$num1 $num2" | awk '{if($1 == $2) print "1"; else print "0"}'
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Add floating point numbers using awk
fac_int_float_add() {
    local num1="$1"
    local num2="$2"
    echo "$num1 $num2" | awk '{printf "%.6f", $1 + $2}'
}

# Subtract floating point numbers using awk
fac_int_float_subtract() {
    local num1="$1"
    local num2="$2"
    echo "$num1 $num2" | awk '{printf "%.6f", $1 - $2}'
}

# Multiply floating point numbers using awk
fac_int_float_multiply() {
    local num1="$1"
    local num2="$2"
    echo "$num1 $num2" | awk '{printf "%.6f", $1 * $2}'
}

# Divide floating point numbers using awk
fac_int_float_divide() {
    local num1="$1"
    local num2="$2"
    if [ "$num2" = "0" ] || [ -z "$num2" ]; then
        echo "0"
    else
        echo "$num1 $num2" | awk '{printf "%.6f", $1 / $2}'
    fi
}

# Calculate percentage using awk
fac_int_calculate_percentage() {
    local part="$1"
    local total="$2"
    if [ "$total" = "0" ] || [ -z "$total" ]; then
        echo "0"
    else
        echo "$part $total" | awk '{printf "%.2f", ($1 * 100) / $2}'
    fi
}

# Calculate average using awk
fac_int_calculate_average() {
    local sum="$1"
    local count="$2"
    if [ "$count" = "0" ] || [ -z "$count" ]; then
        echo "0"
    else
        echo "$sum $count" | awk '{printf "%.3f", $1 / $2}'
    fi
}

# Calculate variance using awk
fac_int_calculate_variance() {
    local variance_sum="$1"
    local count="$2"
    if [ "$count" = "0" ] || [ -z "$count" ]; then
        echo "0"
    else
        echo "$variance_sum $count" | awk '{printf "%.3f", $1 / $2}'
    fi
}

# Convert bytes to Mbps using awk
fac_int_bytes_to_mbps() {
    local bytes="$1"
    local duration="$2"
    if [ "$duration" = "0" ] || [ -z "$duration" ]; then
        echo "0"
    else
        echo "$bytes $duration" | awk '{printf "%.3f", ($1 / $2) / 1048576}'
    fi
}

# Convert bytes to Kbps using awk
fac_int_bytes_to_kbps() {
    local bytes="$1"
    local duration="$2"
    if [ "$duration" = "0" ] || [ -z "$duration" ]; then
        echo "0"
    else
        echo "$bytes $duration" | awk '{printf "%.2f", ($1 / $2) / 1024}'
    fi
}

# Export functions for use in other modules
export -f fac_int_calculate_duration
export -f fac_int_float_compare
export -f fac_int_float_add
export -f fac_int_float_subtract
export -f fac_int_float_multiply
export -f fac_int_float_divide
export -f fac_int_calculate_percentage
export -f fac_int_calculate_average
export -f fac_int_calculate_variance
export -f fac_int_bytes_to_mbps
export -f fac_int_bytes_to_kbps
