#!/bin/bash

# Test file for str.sh functions

# Test capitalize function
test_capitalize_basic() {
    # Test basic functionality
    local result=$(capitalize "hello world")
    assert_equals "HELLO WORLD" "$result" "capitalize should convert string to uppercase"
}

test_capitalize_mixed_case() {
    # Test with mixed case input
    local result=$(capitalize "Hello World")
    assert_equals "HELLO WORLD" "$result" "capitalize should convert mixed case to uppercase"
}

test_capitalize_numbers_special() {
    # Test with numbers and special characters
    local result=$(capitalize "hello123!@#")
    assert_equals "HELLO123!@#" "$result" "capitalize should handle numbers and special characters"
}

test_capitalize_empty_string() {
    # Test with empty string
    local result=$(capitalize "")
    assert_equals "" "$result" "capitalize should handle empty strings"
}

# Test normalize function
test_normalize_spaces() {
    # Test space normalization
    local result=$(normalize "  hello  world  ")
    assert_equals "hello world" "$result" "normalize should trim and normalize spaces"
}

test_normalize_tabs() {
    # Test tab normalization
    local result=$(normalize "hello\tworld")
    assert_equals "hello world" "$result" "normalize should convert tabs to spaces"
}

test_normalize_newlines() {
    # Test newline normalization
    local result=$(normalize "hello\nworld")
    assert_equals "hello world" "$result" "normalize should convert newlines to spaces"
}

test_normalize_mixed_whitespace() {
    # Test with mixed whitespace
    local input=$'hello\n\tworld  test'
    local result=$(normalize "$input")
    assert_equals "hello world test" "$result" "normalize should handle mixed whitespace"
}

test_normalize_empty_string() {
    # Test with empty string
    local result=$(normalize "")
    assert_equals "" "$result" "normalize should handle empty strings"
}

# Test ansi function
test_ansi_basic_formatting() {
    # Test basic ANSI formatting
    local result=$(ansi "31" "Red text")
    
    # The expected result should contain the ANSI escape codes for red text (31) and reset (0)
    # \033[0m\033[31mRed text\033[0m
    assert_equals $'\033[0m\033[31mRed text\033[0m' "$result" "ansi should format text with color code 31 (red)"
}

test_ansi_multiple_codes() {
    # Test multiple ANSI codes (bold green)
    local result=$(ansi "1;32" "Bold green text")
    
    # The expected result should contain the ANSI escape codes for bold green text (1;32) and reset (0)
    assert_equals $'\033[0m\033[1;32mBold green text\033[0m' "$result" "ansi should format text with multiple codes 1;32 (bold green)"
}

test_ansi_background_color() {
    # Test background color
    local result=$(ansi "41;97" "White on red")
    
    # The expected result should contain the ANSI escape codes for white text on red background (41;97) and reset (0)
    assert_equals $'\033[0m\033[41;97mWhite on red\033[0m' "$result" "ansi should format text with background color 41;97"
}

test_ansi_empty_text() {
    # Test with empty text
    local result=$(ansi "31" "")
    
    # The expected result should just be the ANSI codes with no text
    assert_equals $'\033[0m\033[31m\033[0m' "$result" "ansi should handle empty text"
}

test_ansi_empty_code() {
    # Test with empty ANSI code
    local result=$(ansi "" "Some text")
    
    # The expected result should just be the text with reset codes
    assert_equals $'\033[0m\033[mSome text\033[0m' "$result" "ansi should handle empty code"
}