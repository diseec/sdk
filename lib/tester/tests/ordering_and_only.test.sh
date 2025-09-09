#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ EXAMPLE WITH "ONLY" FUNCTIONALITY                                       ┃
# ┃ This demonstrates the new "only" feature and maintained test ordering   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Test functions run in the order they appear in the file, not alphabetically

test_zebra_first() {
    # This should run first despite starting with 'z'
    assert_equals "zebra" "zebra" "Zebra test should run first"
}

test_apple_second() {
    # This should run second despite starting with 'a'
    assert_equals "apple" "apple" "Apple test should run second"
}

# Test with "only" - when any test has _only suffix, only those tests run
test_banana_third_only() {
    # This test will run exclusively when "only" mode is active
    assert_equals "banana" "banana" "Banana test should run in only mode"
}

test_cherry_fourth() {
    # This should run fourth normally, but will be skipped in "only" mode
    assert_equals "cherry" "cherry" "Cherry test should run fourth"
}

# Another "only" test - both "only" tests will run in order
test_date_fifth_only() {
    # This test will also run in "only" mode, after the banana test
    assert_equals "date" "date" "Date test should run in only mode after banana"
}

test_elderberry_sixth() {
    # This should run last normally, but will be skipped in "only" mode
    assert_equals "elderberry" "elderberry" "Elderberry test should run last"
}

# Expected execution order:
# Normal mode: zebra -> apple -> banana -> cherry -> date -> elderberry
# Only mode:   banana -> date (only tests with _only suffix)
