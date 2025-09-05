#!/usr/bin/env bash
# E2E Test Helpers - Common functions for E2E tests

# Import required libraries if not already done
if [ -z "${TESTER_LIB_DIR:-}" ]; then
    export D_SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
    export TESTER_LIB_DIR="$D_SDK_DIR/lib/tester"
    source "$TESTER_LIB_DIR/e2e_core.sh"
fi

# Create a temporary repository for Git testing
e2e_create_git_repo() {
    local repo_name="${1:-test-repo}"
    local repo_dir="$E2E_SCENARIO_DIR/$repo_name"
    
    # Create repo directory
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    
    # Initialize git
    git init --quiet
    git config user.name "E2E Test"
    git config user.email "e2e-test@example.com"
    
    # Add some initial files
    echo "# Test Repository" > README.md
    mkdir -p src
    echo "console.log('Hello, world!');" > src/index.js
    echo "node_modules/" > .gitignore
    
    # Initial commit
    git add .
    git commit -m "Initial commit" --quiet
    
    echo "$repo_dir"
}

# Create a test docker-compose.yaml file
e2e_create_docker_compose() {
    local dir="${1:-$E2E_SCENARIO_DIR}"
    local file="$dir/docker-compose.yaml"
    
    mkdir -p "$dir"
    
    cat > "$file" << EOF
version: '3'

services:
  test-service:
    image: alpine:latest
    command: sh -c "echo 'Hello from test service' && sleep 5"
    volumes:
      - ./:/app
    working_dir: /app
EOF
    
    echo "$file"
}

# Create a basic package.json file for testing
e2e_create_package_json() {
    local dir="${1:-$E2E_SCENARIO_DIR}"
    local file="$dir/package.json"
    
    mkdir -p "$dir"
    
    cat > "$file" << EOF
{
  "name": "e2e-test",
  "version": "1.0.0",
  "description": "E2E Test Project",
  "main": "index.js",
  "scripts": {
    "test": "echo 'Running tests' && exit 0",
    "start": "echo 'Starting application' && exit 0",
    "build": "echo 'Building application' && exit 0"
  },
  "author": "E2E Test",
  "license": "MIT"
}
EOF
    
    echo "$file"
}

# Wait for a specific condition (function that returns true)
e2e_wait_for() {
    local condition_function="$1"
    local timeout="${2:-30}"
    local interval="${3:-1}"
    local description="${4:-condition}"
    
    echo -e "${COLOR_MUTED}Waiting for $description (timeout: ${timeout}s)...${NC}"
    
    local elapsed=0
    while ! $condition_function; do
        sleep "$interval"
        elapsed=$((elapsed + interval))
        if [ $elapsed -ge $timeout ]; then
            echo -e "${COLOR_ERROR}Timeout waiting for $description after ${timeout}s${NC}"
            return 1
        fi
    done
    
    echo -e "${COLOR_MUTED}$description satisfied after ${elapsed}s${NC}"
    return 0
}

# Mock SDK CLI command (useful for testing without running actual commands)
e2e_mock_sdk_cli() {
    local behavior="$1"
    local mock_file="$E2E_TEST_TEMP_DIR/mock_cli"
    
    # Create mock script
    cat > "$mock_file" << EOF
#!/bin/bash
$behavior
EOF
    
    chmod +x "$mock_file"
    
    # Set SDK command to use mock
    export E2E_SDK_COMMAND="$mock_file"
    
    echo -e "${COLOR_WARNING}SDK CLI command mocked. Behavior: $behavior${NC}"
}

# Create a config file for testing
e2e_create_config() {
    local dir="${1:-$E2E_SCENARIO_DIR}"
    local file="$dir/config.json"
    local content="${2:-'{\"environment\":\"test\",\"debug\":true}'}"
    
    mkdir -p "$dir"
    echo "$content" > "$file"
    
    echo "$file"
}

# Create a test environment setup
e2e_setup_test_project() {
    local project_name="${1:-test-project}"
    local project_dir="$E2E_SCENARIO_DIR/$project_name"
    
    # Create project directory
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # Create project files
    e2e_create_package_json "$project_dir"
    e2e_create_docker_compose "$project_dir"
    e2e_create_config "$project_dir"
    
    # Create source code
    mkdir -p "$project_dir/src"
    echo "console.log('Hello from E2E test project');" > "$project_dir/index.js"
    
    # Create a basic README
    cat > "$project_dir/README.md" << EOF
# E2E Test Project

This is a test project for E2E testing of the SDK CLI.
EOF
    
    echo "$project_dir"
}

# Export helper functions
export -f e2e_create_git_repo
export -f e2e_create_docker_compose
export -f e2e_create_package_json
export -f e2e_wait_for
export -f e2e_mock_sdk_cli
export -f e2e_create_config
export -f e2e_setup_test_project
