#!/bin/bash

# Test for the 'config submodule_select' command

# Suite setup - runs once before all tests in this file
setup_test() {
    # Create a mock .gitmodules file for testing
    cat > "$TEST_WORKSPACE/.gitmodules" << EOF
[submodule "packages/test-submodule"]
	path = packages/test-submodule
	url = https://github.com/test/test-submodule.git

[submodule "services/submodule1"]
	path = services/submodule1
	url = https://github.com/test/submodule1.git

[submodule "packages/submodule2"]
	path = packages/submodule2
	url = https://github.com/test/submodule2.git

[submodule "services/submodule3"]
	path = services/submodule3
	url = https://github.com/test/submodule3.git

[submodule "packages/duplicate-submodule"]
	path = packages/duplicate-submodule
	url = https://github.com/test/duplicate-submodule.git

[submodule "services/scope-test-submodule"]
	path = services/scope-test-submodule
	url = https://github.com/test/scope-test-submodule.git
EOF
}

# Test interactive submodule selection with here string (selecting options 1,2)
test_config_submodule_select_interactive_only() {
    # If config exists, we'll need 'y' to confirm overwrite, then '1,2' for selection
    # If it's the first run, just '1,2' is needed
    # This handles both cases with a single multi-line input
    local output
    output=$(D config submodule_select <<< $'1,2')
    D config --scope=repository set submodules "adfs,afsd"
    D config pri
    # Verify the submodules were added to the configuration
    local submodules
    submodules=$(D config --scope=repository get submodules)
    
    # Based on our .gitmodules file and selecting options 1,2, 
    # we should have test-submodule and submodule1 selected
    assert_not_empty "$submodules" "Submodules array should exist"
    assert_contains "$submodules" "test-submodule" "Submodules array should contain test-submodule (option 1)"
    assert_contains "$submodules" "submodule1" "Submodules array should contain submodule1 (option 2)"
    assert_not_contains "$submodules" "submodule2" "Submodules array should not contain unselected options"
}

# Test interactive submodule selection with "all" option
test_config_submodule_select_all() {
    # If config exists, we'll need 'y' to confirm overwrite, then 'all' for selection
    local output
    output=$(D config submodule_select <<< $'y\nall')
    
    # Verify all submodules were added to the configuration
    local submodules
    submodules=$(D config --scope=repository get submodules)
    
    # All 6 submodules from our test file should be included
    assert_not_empty "$submodules" "Submodules array should exist"
    assert_contains "$submodules" "test-submodule" "Submodules array should contain test-submodule"
    assert_contains "$submodules" "submodule1" "Submodules array should contain submodule1"
    assert_contains "$submodules" "submodule2" "Submodules array should contain submodule2"
    assert_contains "$submodules" "submodule3" "Submodules array should contain submodule3"
    assert_contains "$submodules" "duplicate-submodule" "Submodules array should contain duplicate-submodule"
    assert_contains "$submodules" "scope-test-submodule" "Submodules array should contain scope-test-submodule"
}

# Test interactive submodule selection with empty input
test_config_submodule_select_empty() {
    # First set up some initial submodules
    D config submodule_select <<< $'y\n1,2' > /dev/null
    
    # Run the command with empty input
    # If a config exists, we'll first need 'y' to confirm overwrite, then '' for empty selection
    local output
    output=$(D config submodule_select <<< $'y\n')
    
    # The original selections should remain unchanged
    local submodules
    submodules=$(D config --scope=repository get submodules)
    
    assert_contains "$submodules" "test-submodule" "Original selection should be preserved with empty input"
    assert_contains "$submodules" "submodule1" "Original selection should be preserved with empty input"
}

# Test confirmation dialog with "no" response
test_config_submodule_select_confirmation_no() {
    # First set up some initial submodules
    D config submodule_select <<< $'y\n1,2' > /dev/null
    
    # Now run the command but respond "n" to the confirmation prompt
    local output
    output=$(D config submodule_select <<< $'n')
    
    # Original selections should remain unchanged when declining the confirmation
    local submodules
    submodules=$(D config --scope=repository get submodules)
    
    assert_contains "$submodules" "test-submodule" "Original selection should be preserved when declining confirmation"
    assert_contains "$submodules" "submodule1" "Original selection should be preserved when declining confirmation"
    
    # Now test with confirmation "yes" and new selection
    output=$(D config submodule_select <<< $'y\n3')
    
    # Verify the new selection was applied
    submodules=$(D config --scope=repository get submodules)
    assert_contains "$submodules" "submodule2" "New selection should be applied when confirming with yes"
}
