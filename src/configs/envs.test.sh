#!/bin/bash

# =============================================================================
# ENVIRONMENT SYSTEM TEST SCRIPT
# =============================================================================
# Simple test script to validate the modular environment system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result function
test_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name${message:+ - $message}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test if file exists and is readable
test_file_exists() {
    local file="$1"
    local name="$2"
    
    if [ -f "$file" ] && [ -r "$file" ]; then
        test_result "$name file exists and is readable" "PASS"
    else
        test_result "$name file exists and is readable" "FAIL" "File: $file"
    fi
}

# Test if function exists
test_function_exists() {
    local func_name="$1"
    
    if declare -f "$func_name" >/dev/null 2>&1; then
        test_result "Function '$func_name' exists" "PASS"
    else
        test_result "Function '$func_name' exists" "FAIL"
    fi
}

# Test if variable is set and not empty
test_variable_set() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    
    if [ -n "$var_value" ]; then
        test_result "Variable '$var_name' is set" "PASS"
    else
        test_result "Variable '$var_name' is set" "FAIL"
    fi
}

echo "=============================================================================="
echo "Environment System Test Suite"
echo "=============================================================================="

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\n${YELLOW}Testing module files...${NC}"

# Test module files exist
test_file_exists "$SCRIPT_DIR/config/constants.sh" "Constants module"
test_file_exists "$SCRIPT_DIR/utils/path-discovery.sh" "Path discovery module"
test_file_exists "$SCRIPT_DIR/utils/git-utils.sh" "Git utilities module"
test_file_exists "$SCRIPT_DIR/utils/env-detection.sh" "Environment detection module"
test_file_exists "$SCRIPT_DIR/envs.sh" "Main environment"

echo -e "\n${YELLOW}Loading environment system...${NC}"

# Set up minimal required environment for testing
export KIT_DIR="$SCRIPT_DIR/.."
export IS_KIT_CLI_="false"
export IS_IN_KIT_CONTAINER="false"

# Source the main environment file
if source "$SCRIPT_DIR/envs.sh" 2>/dev/null; then
    test_result "Environment system loads without errors" "PASS"
else
    test_result "Environment system loads without errors" "FAIL"
    echo "Cannot continue with tests"
    exit 1
fi

echo -e "\n${YELLOW}Testing functions...${NC}"

# Test that all functions are available
test_function_exists "auto_discover_project_root_dir"
test_function_exists "get_org_dir"
test_function_exists "get_cache_dir"
test_function_exists "get_git_config_file"
test_function_exists "get_repo_url"
test_function_exists "get_repo_name"
test_function_exists "get_current_branch"
test_function_exists "is_online"
test_function_exists "is_in_container"
test_function_exists "is_monorepo"
test_function_exists "has_submodules"
test_function_exists "get_kit_version"
test_function_exists "validate_environment"

echo -e "\n${YELLOW}Testing constants...${NC}"

# Test constants are set
test_variable_set "ORG_NAME"
test_variable_set "KIT_NAME"
test_variable_set "PROJECT_MOUNT_DIR_NAME"
test_variable_set "IMAGE_REGISTRY_URL"
test_variable_set "KIT_IMAGE"
test_variable_set "REPO_HUB_URL"
test_variable_set "KIT_RELATIVE_PATH"

echo -e "\n${YELLOW}Testing computed variables...${NC}"

# Test computed variables are set
test_variable_set "ROOT_DIR"
test_variable_set "KIT_SRC_DIR"
test_variable_set "CLI"
test_variable_set "CLI_BASE"
test_variable_set "ORG_DIR"
test_variable_set "ORG_CACHE_DIR"
test_variable_set "IS_ONLINE"
test_variable_set "IS_IN_CONTAINER"
test_variable_set "IS_MONOREPO"
test_variable_set "HAS_SUBMODULES"
test_variable_set "VERSION"
test_variable_set "CURRENT_BRANCH"

echo -e "\n${YELLOW}Testing environment validation...${NC}"

# Test environment validation
if validate_environment >/dev/null 2>&1; then
    test_result "Environment validation passes" "PASS"
else
    test_result "Environment validation passes" "FAIL"
fi

echo -e "\n=============================================================================="
echo "Test Results Summary"
echo "=============================================================================="
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed.${NC}"
    exit 1
fi
