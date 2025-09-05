#!/bin/bash

# Project setup utilities for testing framework
# This script provides functions for setting up test projects

# Prevent multiple sourcing
if [[ "${SDK_LIB_TESTER_SETUP_SOURCED:-}" == "1" ]]; then
  return 0
fi
SDK_LIB_TESTER_SETUP_SOURCED=1

# Setup a new test project
sdk_lib_tester_setup_project() {
  local project_name="$1"
  local template="${2:-basic}"
  
  logit -i "Setting up test project: $(ansi "1;97" "$project_name")"
  
  # Create project directory
  local project_dir="$D_CTX_DIR/test-projects/$project_name"
  
  if [[ -d "$project_dir" ]]; then
    logit -w "Project directory already exists: $project_dir"
    read -p "$(ansi "35" "?") Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      logit -e "Aborted"
      return 1
    fi
    rm -rf "$project_dir"
  fi
  
  mkdir -p "$project_dir"
  
  # Copy template files
  local template_dir="$D_SDK_DIR/lib/tester/templates/$template"
  
  if [[ ! -d "$template_dir" ]]; then
    # If template doesn't exist, use the basic template
    logit -w "Template not found: $template, using basic template"
    template_dir="$D_SDK_DIR/lib/tester/templates/basic"
    
    # Create basic template if it doesn't exist
    if [[ ! -d "$template_dir" ]]; then
      logit -i "Creating basic template"
      mkdir -p "$template_dir"
      
      # Create package.json
      cat > "$template_dir/package.json" << EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project for SDK testing",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@diseec/sdk": "file:../../../"
  }
}
EOF
      
      # Create cli file
      cat > "$template_dir/cli" << EOF
#!/bin/bash

source "\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)/node_modules/@diseec/sdk/index.sh"

c=\$1; shift; case \$c in
    # Custom command implementation
    hello)
        echo "Hello from test project!"
    ;;

    # Default to SDK commands
    *) cli_core \$c "\$@" ;;
esac
EOF
      
      # Make cli executable
      chmod +x "$template_dir/cli"
      
      # Create README.md
      cat > "$template_dir/README.md" << EOF
# Test Project

This is a basic test project for SDK testing.
EOF
    fi
  fi
  
  # Copy template files to project directory
  cp -r "$template_dir/"* "$project_dir/"
  
  # Update package.json with project name
  if [[ -f "$project_dir/package.json" ]]; then
    sed -i '' "s/\"name\": \"test-project\"/\"name\": \"$project_name\"/" "$project_dir/package.json"
    sed -i '' "s/\"description\": \"Test project for SDK testing\"/\"description\": \"$project_name - Test project for SDK testing\"/" "$project_dir/package.json"
  fi
  
  # Make cli executable
  if [[ -f "$project_dir/cli" ]]; then
    chmod +x "$project_dir/cli"
  fi
  
  logit -o "Project setup complete: $project_dir"
  logit -i "To initialize the project, run:"
  logit -l "cd $project_dir && npm install"
  
  return 0
}

# Initialize a test project (install dependencies)
sdk_lib_tester_init_project() {
  local project_name="$1"
  
  local project_dir="$D_CTX_DIR/test-projects/$project_name"
  
  if [[ ! -d "$project_dir" ]]; then
    logit -e "Project directory not found: $project_dir"
    return 1
  fi
  
  logit -i "Initializing test project: $(ansi "1;97" "$project_name")"
  
  # Navigate to project directory and install dependencies
  (
    cd "$project_dir" || return 1
    npm install
  )
  
  if [[ $? -ne 0 ]]; then
    logit -e "Failed to initialize project: $project_name"
    return 1
  fi
  
  logit -o "Project initialized: $project_name"
  
  return 0
}

# Run a command in a test project
sdk_lib_tester_run_in_project() {
  local project_name="$1"
  shift
  local cmd="$@"
  
  local project_dir="$D_CTX_DIR/test-projects/$project_name"
  
  if [[ ! -d "$project_dir" ]]; then
    logit -e "Project directory not found: $project_dir"
    return 1
  fi
  
  logit -i "Running in project $(ansi "1;97" "$project_name"): $(ansi "90" "$cmd")"
  
  # Navigate to project directory and run command
  (
    cd "$project_dir" || return 1
    eval "$cmd"
  )
  
  return $?
}

# Create a temporary test project
sdk_lib_tester_create_temp_project() {
  local template="${1:-basic}"
  
  # Generate a unique project name
  local project_name="temp-$(date +%s)"
  
  # Setup the project
  sdk_lib_tester_setup_project "$project_name" "$template"
  
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  
  # Initialize the project
  sdk_lib_tester_init_project "$project_name"
  
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  
  # Return the project name
  echo "$project_name"
  
  return 0
}

# Clean up a temporary test project
sdk_lib_tester_cleanup_temp_project() {
  local project_name="$1"
  
  local project_dir="$D_CTX_DIR/test-projects/$project_name"
  
  if [[ ! -d "$project_dir" ]]; then
    logit -w "Project directory not found: $project_dir"
    return 0
  fi
  
  logit -i "Cleaning up test project: $(ansi "1;97" "$project_name")"
  
  rm -rf "$project_dir"
  
  logit -o "Project cleaned up: $project_name"
  
  return 0
}
