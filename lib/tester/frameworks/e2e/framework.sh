#!/bin/bash
# E2E testing framework
# This script provides helpers specifically for end-to-end testing

# Variables to store command output
E2E_STDOUT=""
E2E_STDERR=""
E2E_EXIT_CODE=0
E2E_TEMP_DIR=""
E2E_LOG_DIR=""
E2E_SDK_COMMAND=${E2E_SDK_COMMAND:-"$D_SDK_DIR/$D_CLI_LOCAL_NAME"}

# E2E test initialization
e2e_init() {
    # Set up E2E test environment
    test_info "Initializing E2E test environment"
    
    # Set default test timeout (longer for E2E tests)
    export TEST_TIMEOUT_SECONDS=${TEST_TIMEOUT_SECONDS:-180}
    
    # Create isolated environment
    E2E_TEMP_DIR=$(mktemp -d)
    export E2E_TEMP_DIR
    export E2E_ORIGINAL_PWD=$(pwd)
    export E2E_TEST_PROJECT="$E2E_TEMP_DIR/test-project"
    export E2E_LOG_DIR="$E2E_TEMP_DIR/logs"
    
    # Create test project and logs directories
    mkdir -p "$E2E_TEST_PROJECT"
    mkdir -p "$E2E_LOG_DIR"
    
    # Clean up on exit
    trap e2e_cleanup EXIT
}

# E2E test cleanup
e2e_cleanup() {
    # Return to original directory
    if [ -n "$E2E_ORIGINAL_PWD" ]; then
        cd "$E2E_ORIGINAL_PWD" 2>/dev/null || true
    fi
    
    # Clean up temp directory if no failures
    if [ "${FAILED_COUNT:-0}" -eq 0 ]; then
        if [ -n "$E2E_TEMP_DIR" ] && [ -d "$E2E_TEMP_DIR" ]; then
            rm -rf "$E2E_TEMP_DIR"
        fi
    else
        test_warn "Test logs preserved in $E2E_LOG_DIR due to test failures"
    fi
    
    test_info "E2E test environment cleaned up"
}

# Set up a test project with SDK
e2e_setup_test_project() {
    local project_name="${1:-test-project}"
    
    test_info "Setting up test project: $project_name"
    
    # Create project directory
    mkdir -p "$E2E_TEMP_DIR/$project_name"
    cd "$E2E_TEMP_DIR/$project_name" || return 1
    
    # Initialize basic project structure
    mkdir -p "bin" "src" "docs"
    
    # Create a minimal package.json
    cat > "package.json" << EOF
{
  "name": "$project_name",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@diseec/sdk": "latest"
  }
}
EOF

    # Create a minimal CLI script
    cat > "cli" << EOF
#!/bin/bash
# Project CLI
source "\$(dirname "\$0")/node_modules/@diseec/sdk/index.sh"
source "\$D_SDK_DIR/index.sh"

# Additional project-specific commands can be added here
c=\$1; shift; case \$c in
    custom) echo "Custom command" ;;
    *)     cli_main "\$c" "\$@" ;;
esac
EOF
    chmod +x "cli"
    
    test_info "Test project setup complete"
}

# Run a command in the E2E test environment
e2e_run_command() {
    local command="$1"
    local dir="${2:-$E2E_TEST_PROJECT}"
    
    # Ensure we're in the right directory
    cd "$dir" || return 1
    
    # Clear previous outputs
    E2E_STDOUT=""
    E2E_STDERR=""
    E2E_EXIT_CODE=0
    
    # Run the command and capture output
    local temp_out=$(mktemp)
    local temp_err=$(mktemp)
    
    test_info "Running command: $command"
    
    if eval "$command" >"$temp_out" 2>"$temp_err"; then
        E2E_EXIT_CODE=0
    else
        E2E_EXIT_CODE=$?
    fi
    
    # Save output
    E2E_STDOUT=$(cat "$temp_out")
    E2E_STDERR=$(cat "$temp_err")
    
    # Clean up
    rm -f "$temp_out" "$temp_err"
    
    # Return the exit code
    return $E2E_EXIT_CODE
}

# Assert that a command succeeded
e2e_assert_success() {
    local description="$1"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if [ $E2E_EXIT_CODE -eq 0 ]; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Command failed with exit code $E2E_EXIT_CODE${NC}"
        echo -e "    ${COLOR_MUTED}stderr: $E2E_STDERR${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that a command failed
e2e_assert_failure() {
    local description="$1"
    local expected_code="${2:-}"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    if [ $E2E_EXIT_CODE -ne 0 ]; then
        if [ -n "$expected_code" ] && [ $E2E_EXIT_CODE -ne "$expected_code" ]; then
            format_output "failure" "$description"
            echo -e "    ${COLOR_MUTED}Expected exit code $expected_code, got $E2E_EXIT_CODE${NC}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            return 1
        else
            format_output "success" "$description"
            PASSED_COUNT=$((PASSED_COUNT + 1))
            return 0
        fi
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}Command should have failed but succeeded${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that command output contains a string
e2e_assert_output_contains() {
    local description="$1"
    local expected="$2"
    local stream="${3:-stdout}"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    local output
    if [ "$stream" = "stderr" ]; then
        output="$E2E_STDERR"
    else
        output="$E2E_STDOUT"
    fi
    
    if echo "$output" | grep -q -F "$expected"; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}$stream does not contain: '$expected'${NC}"
        echo -e "    ${COLOR_MUTED}Actual: '${output:0:100}...'${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Assert that command output matches a pattern
e2e_assert_output_matches() {
    local description="$1"
    local pattern="$2"
    local stream="${3:-stdout}"
    ASSERTION_COUNT=$((ASSERTION_COUNT + 1))
    
    local output
    if [ "$stream" = "stderr" ]; then
        output="$E2E_STDERR"
    else
        output="$E2E_STDOUT"
    fi
    
    if echo "$output" | grep -q -E "$pattern"; then
        format_output "success" "$description"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        format_output "failure" "$description"
        echo -e "    ${COLOR_MUTED}$stream does not match pattern: '$pattern'${NC}"
        echo -e "    ${COLOR_MUTED}Actual: '${output:0:100}...'${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Export E2E testing functions
export -f e2e_init e2e_cleanup e2e_setup_test_project
export -f e2e_run_command e2e_assert_success e2e_assert_failure
export -f e2e_assert_output_contains e2e_assert_output_matches

# Setup a Git repository for testing
e2e_setup_git_repo() {
    local repo_dir="${1:-$(pwd)}"
    
    # Ensure the directory exists
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    
    # Initialize Git repo
    git init --quiet
    git config user.name "E2E Test"
    git config user.email "e2e-test@example.com"
    
    # Create initial files if the directory is empty
    if [ -z "$(ls -A)" ]; then
        echo "# Test Repository" > README.md
        echo "node_modules/" > .gitignore
    fi
    
    # Make initial commit if no commits exist
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        git add .
        git commit -m "Initial commit" --quiet
    fi
    
    test_info "Set up Git repository in $repo_dir"
    return 0
}

# Execute the SDK command with specified args and capture output to logs
e2e_execute() {
    local cmd_args=("$@")
    local log_prefix="$(date +%s)-cmd-$(echo "${cmd_args[*]}" | tr -c '[:alnum:]' '-' | tr -s '-' | cut -c1-50)"
    local stdout_file="$E2E_LOG_DIR/${log_prefix}.stdout"
    local stderr_file="$E2E_LOG_DIR/${log_prefix}.stderr"
    local combined_file="$E2E_LOG_DIR/${log_prefix}.log"
    
    # Log the command being executed
    echo "$ $E2E_SDK_COMMAND ${cmd_args[*]}" > "$combined_file"
    echo "TIMESTAMP: $(date)" >> "$combined_file"
    echo "WORKING DIR: $(pwd)" >> "$combined_file"
    echo "----------------------------------------" >> "$combined_file"
    
    # Execute with timeout
    local exit_code=0
    if ! timeout "$TEST_TIMEOUT_SECONDS" "$E2E_SDK_COMMAND" "${cmd_args[@]}" > "$stdout_file" 2> "$stderr_file"; then
        exit_code=$?
        # Check if it was a timeout
        if [ $exit_code -eq 124 ]; then
            echo "Command timed out after ${TEST_TIMEOUT_SECONDS}s" >> "$combined_file"
        fi
    fi
    
    # Capture outputs
    export E2E_STDOUT=$(cat "$stdout_file")
    export E2E_STDERR=$(cat "$stderr_file")
    export E2E_EXIT_CODE=$exit_code
    
    # Log results to combined file
    echo "EXIT CODE: $exit_code" >> "$combined_file"
    echo "----------------------------------------" >> "$combined_file"
    echo "STDOUT:" >> "$combined_file"
    cat "$stdout_file" >> "$combined_file"
    echo "----------------------------------------" >> "$combined_file"
    echo "STDERR:" >> "$combined_file"
    cat "$stderr_file" >> "$combined_file"
    
    return $exit_code
}

# Setup a scenario - an isolated test environment for a specific test case
e2e_setup_scenario() {
    local scenario_name="$1"
    local scenario_dir="$E2E_TEMP_DIR/scenarios/$scenario_name"
    
    # Create scenario directory
    mkdir -p "$scenario_dir"
    
    # Change to scenario directory
    cd "$scenario_dir"
    
    # Export variables
    export E2E_CURRENT_SCENARIO="$scenario_name"
    export E2E_SCENARIO_DIR="$scenario_dir"
    
    test_info "Setting up scenario: $scenario_name in $scenario_dir"
}

# Setup a basic project for testing
e2e_setup_project() {
    local project_name="${1:-test-project}"
    local project_dir="$E2E_TEMP_DIR/$project_name"
    
    # Create project directory
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    # Create basic project files
    echo '{"name":"'"$project_name"'","version":"1.0.0"}' > package.json
    
    echo "version: '3'" > docker-compose.yaml
    echo "services:" >> docker-compose.yaml
    echo "  app:" >> docker-compose.yaml
    echo "    image: alpine:latest" >> docker-compose.yaml
    echo "    command: sh -c 'echo Hello from $project_name'" >> docker-compose.yaml
    
    # Create project directories
    mkdir -p src
    mkdir -p tests
    
    # Create a README
    echo "# $project_name" > README.md
    echo "Test project for E2E testing" >> README.md
    
    test_info "Set up test project in $project_dir"
    return 0
}

export -f e2e_setup_git_repo e2e_execute e2e_setup_scenario e2e_setup_project
