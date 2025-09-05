#!/bin/bash

# TEST: Container Environment Example
# DESCRIPTION: Demonstrates container-aware testing capabilities

# Source testing framework
source_once "$D_SDK_DIR/lib/tester/index.sh"

# Check if we're running in a container
if [[ "${SDK_TESTER_IN_CONTAINER:-0}" == "1" ]]; then
  sdk_lib_tester_utils_section "Container Tests"
  
  # Test container-specific functionality
  assert_true "[[ -f '/entrypoint.sh' ]]" "Container should have entrypoint.sh"
  assert_success "which docker" "Docker should be available in container"
  
  # Get Docker version
  docker_version=$(docker --version)
  assert_contains "$docker_version" "Docker version" "Docker version should be available"
  
  logit -o "Successfully verified container environment"
else
  # Skip test if not in container
  sdk_lib_tester_utils_skip "This test must run in a container"
fi

exit $(( SDK_TESTER_ASSERT_FAILED > 0 ? 1 : 0 ))
