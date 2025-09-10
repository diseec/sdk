#!/bin/bash

# Test for the 'config select_submodule' command

# Suite setup - runs once before all tests in this file
setup_test() {
    # Initialize config
    D config init > /dev/null
    
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

# Test selecting a submodule
test_config_select_submodule_adds_to_array() {
    # Select a submodule
    local output
    output=$(D config select_submodule "test-submodule")
    
    # Verify the command succeeded
    assert_command_success "cd \"$TEST_WORKSPACE\" && D config select_submodule \"test-submodule\"" "Select submodule command should succeed"
    
    # Verify the submodule was added to the configuration
    # First, check if there's a submodules array in the context config
    local submodules
    submodules=$(D config --scope=context get context.submodules)
    
    assert_not_empty "$submodules" "Submodules array should exist"
    assert_contains "$submodules" "test-submodule" "Submodules array should contain the selected submodule"
}

# Test selecting multiple submodules
test_config_select_multiple_submodules() {
    # Select multiple submodules
    D config select_submodule "submodule1" > /dev/null
    D config select_submodule "submodule2" > /dev/null
    D config select_submodule "submodule3" > /dev/null
    
    # Verify all submodules were added
    local submodules
    submodules=$(D config --scope=context get context.submodules)
    
    assert_contains "$submodules" "submodule1" "Submodules array should contain submodule1"
    assert_contains "$submodules" "submodule2" "Submodules array should contain submodule2"
    assert_contains "$submodules" "submodule3" "Submodules array should contain submodule3"
}

# Test selecting the same submodule twice
test_config_select_duplicate_submodule() {
    # Select the same submodule twice
    D config select_submodule "duplicate-submodule" > /dev/null
    D config select_submodule "duplicate-submodule" > /dev/null
    
    # Verify how duplicates are handled
    # This test might need adjustment based on the actual implementation
    # Some systems might allow duplicates, others might prevent them
    
    local submodules
    submodules=$(D config --scope=context get context.submodules)
    
    # Count occurrences of "duplicate-submodule" in the array
    local count
    count=$(echo "$submodules" | grep -o "duplicate-submodule" | wc -l)
    
    # Adjust this assertion based on expected behavior
    # Here we're assuming duplicates are prevented
    assert_equals "1" "$count" "Duplicate submodules should be handled properly"
}

# Test that submodules are stored in context scope
test_config_submodules_in_context_scope() {
    # Select a submodule
    D config select_submodule "scope-test-submodule" > /dev/null
    
    # Verify it's in the context scope but not in other scopes
    local context_submodules
    context_submodules=$(D config --scope=context get context.submodules)
    
    assert_contains "$context_submodules" "scope-test-submodule" "Submodule should be in context scope"
    
    # Check repository scope (might not have context.submodules key at all)
    local repo_submodules
    repo_submodules=$(D config --scope=repository get context.submodules 2>/dev/null || echo "not_found")
    
    if [ "$repo_submodules" != "not_found" ]; then
        assert_not_contains "$repo_submodules" "scope-test-submodule" "Submodule should not be in repository scope"
    fi
    
    # Check user scope (might not have context.submodules key at all)
    local user_submodules
    user_submodules=$(D config --scope=user get context.submodules 2>/dev/null || echo "not_found")
    
    if [ "$user_submodules" != "not_found" ]; then
        assert_not_contains "$user_submodules" "scope-test-submodule" "Submodule should not be in user scope"
    fi
}
