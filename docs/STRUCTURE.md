# SDK Structure Documentation

## Overview

The DISEEC SDK is a comprehensive toolkit designed to automate and streamline development workflows. It provides a unified command-line interface (CLI) that can be extended by projects that install it. The SDK is built with shell scripting at its core and follows a modular architecture that enables consistent development experiences across different projects.

The SDK is designed to be installed via npm into a target package (which we refer to as the "context"). It provides all utilities required for developers to automate and ease the development process in a consistent and predictable environment.

## Installation and Context Setup

The SDK is installed via npm into a target project:

```bash
npm install @diseec/sdk
```

After installation, the project must have a special file named `cli` at its root. This file is crucial as:

1. The SDK uses this file to define the root of the project (the "context")
2. This file serves as the entry point for all commands
3. It extends the SDK's base functionality while allowing for project-specific customizations

You can find an example of a typical `cli` file in the SDK's `examples/cli` directory. This file will always source the SDK's `index.sh` at the beginning:

```bash
#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/node_modules/@diseec/sdk/index.sh"

# Command routing and customizations follow...
```

## Core Concepts

### Context-Based Architecture

The SDK operates on a context-based architecture, where:

- **Context**: A project that has installed the SDK as a dependency
- **Context Discovery**: The SDK automatically discovers the root of a project by looking for a `cli` file
- **Context Isolation**: Commands run in isolation to prevent side effects between processes
- **Context Variables**: Environment variables are set up to define paths, state, and capabilities for the current context

### Bootstrap Process

The bootstrap process is a critical component of the SDK. It's responsible for initializing the environment, setting up paths, detecting the project context, and providing error handling capabilities. The process consists of several key stages:

### 1. Entry Point (index.sh)

When a command is executed, the context's `cli` file sources the SDK's `index.sh`, which:

- Processes command-line arguments (like `--debug`, `--log-level`, etc.)
- Sets the `D_SDK_DIR` variable to locate the SDK
- Sources shared utilities and bootstraps the environment
- Initializes debugging capabilities
- Sets up the working directory to the context directory

### 2. Environment Setup (bootstrap/environment)

The environment setup is modular and handles:

- **Constants**: Defines organization and project constants (`D_ORG_NAME`, `D_SDK_NAME`, etc.)
- **Path Discovery**: Automatically discovers the project context (`sdk_boo_env_uti_cli_auto_discovery`)
- **Git Integration**: Extracts git repository information without requiring git commands
- **Container Detection**: Identifies if code is running inside a container
- **Environment Validation**: Validates the environment setup and warns about missing components

Key environment utilities include:

- **cli_auto_discovery.sh**: Finds the project root by looking for the `cli` file
- **env_detection.sh**: Detects container status, submodules, and SDK version
- **git_fallback_utils.sh**: Provides git operations that work even when git is not available
- **validate_environment.sh**: Ensures the environment is correctly configured

### 3. Debugging (bootstrap/debug.sh)

The debugging system provides:

- Error tracing with stack traces
- System information collection
- Environment variable reporting
- Customizable log levels (`DEBUG`, `INFO`, `WARNING`, `ERROR`)
- Custom error handlers

### 4. Hooks (bootstrap/hooks.sh)

The hooks system allows for extension points in the SDK lifecycle:

- Executes custom functions at predefined points
- Enables projects to respond to SDK events
- Allows for context-specific customizations

### 5. Output and Completion

After bootstrap:

- All environment variables are available to child processes
- The working directory is set to the context directory
- Error handling is active with stack traces
- Commands are ready to be executed in the proper context

### Container-Based Execution

The SDK is designed to run as much as possible in its own container, which has all the dependencies and tools required for the CLI to work. This container provides a predictable and consistent environment across different systems.

This approach is implemented through the "safely" concept:

- When a command is marked with `safely`, the SDK tries to run that part of the code in the container
- This ensures that all tools and dependencies are available and consistent
- It isolates the execution environment from the host system

Key features of the container-based execution:

- **Safely Concept**: Using the `safely` function runs commands in the SDK container
- **Predictable Environment**: Ensures dependencies and tools are consistent across different systems
- **Container Detection**: The SDK detects if it's already running in a container to prevent nested containers

### Process Isolation

A key design principle of the SDK is that each command execution is isolated from others. This means:

- Every time a command is run, it has no side effects on child processes
- All required files are sourced from the beginning of execution to the end
- This approach grants isolation between processes
- The only exceptions are when we explicitly need to run a new process to proceed

This isolation is primarily achieved through the `cli_ctx` function, which is used across all facades and the main `cli` file. This function:

- Sources the context's `cli` file again in the same shell
- Runs the given command
- Ensures the starting point is always the context's `cli` file

The only exception to this rule is when the context is the SDK itself - in this case, the starting point is the SDK's CLI file, which serves an identical role to the context's `cli` file.

## Facades (SDK Modules)

The SDK is organized into facades (modules) that provide specific functionality. Each facade:

1. Is located in the `facades/` directory
2. Has its own `cli.sh` file that defines the command interface
3. Can be called by the main CLI or other facades

The facades pattern allows for:

- Modular organization of functionality
- Consistent command interfaces
- Easy extension and maintenance

Examples of facades include:

- **git**: Git operations and workflows
- **docker**: Docker operations and management
- **format**: Code formatting utilities
- **install**: Installation procedures
- **secret**: Secret management

Each facade's `cli.sh` is integrated into the main `cli.sh` at the root of the SDK, allowing the modules to be accessed through the unified command interface.

## Directory Structure

```
sdk/
├── api/                  # API-related functionality
├── bootstrap/            # Core initialization and environment setup
│   ├── debug.sh          # Debugging utilities
│   ├── environment/      # Environment variable management
│   │   ├── constants.sh  # System constants
│   │   ├── exports.sh    # Environment exports
│   │   ├── index.sh      # Main environment initialization
│   │   └── utils/        # Environment utility functions
│   ├── hooks.sh          # Lifecycle hooks
│   └── index.sh          # Bootstrap entry point
├── cli.sh                # Main CLI command router
├── cmds/                 # Core command implementations
│   ├── any.sh            # Fallback command handler
│   ├── index.sh          # Command initialization
│   ├── options/          # Command options (like --safely)
│   └── status.sh         # Status command implementation
├── docs/                 # Documentation
├── examples/             # Example implementations
│   └── cli               # Example context CLI file
├── facades/              # Modular functionality extensions
│   ├── ai/               # AI-related features
│   ├── config/           # Configuration management
│   ├── docker/           # Docker operations
│   ├── format/           # Code formatting
│   ├── git/              # Git operations and workflows
│   ├── install/          # Installation procedures
│   ├── internet/         # Internet connectivity features
│   ├── secret/           # Secret management
│   └── submodule/        # Git submodule handling
├── index.sh              # SDK entry point
├── informs/              # Informational and status checks
│   ├── cli.sh            # CLI for informational commands
│   ├── index.sh          # Initialization of informational modules
│   └── src_inf_*.sh      # Various information providers
├── shared/               # Shared utilities
│   ├── index.sh          # Shared utilities initialization
│   ├── outputs.sh        # Output formatting
│   ├── utils.sh          # Common utility functions
│   └── wrappers.sh       # Command wrappers
└── templates/            # Project templates
```

## Key Files and Their Roles

### Entry Points

- **index.sh**: The main entry point for the SDK, responsible for bootstrap initialization
- **cli.sh**: The command router that handles command dispatch to appropriate modules
- **facades/\*/cli.sh**: Entry points for specific functionality modules

### Core Framework

- **bootstrap/index.sh**: Initializes the bootstrap process
- **bootstrap/environment/index.sh**: Sets up environment variables and validates the environment
- **shared/utils.sh**: Contains core utility functions including `cli_ctx` and `safely`
- **shared/outputs.sh**: Handles standardized output formatting

## Key Functions and Concepts

### Command Execution

- **cli_ctx()**: Routes commands through the context's CLI entry point
- **cli_core()**: Routes commands through the SDK's base CLI
- **source_once()**: Ensures a script is only sourced once to prevent duplicate initialization
- **source_safely()**: Sources a script only if running in the appropriate environment

### Safety and Containerization

- **safely()**: Ensures commands run in the SDK container for consistency
- **source_safely()**: Sources a script only if running in the appropriate container environment
- **mark_ctx_only()**: Ensures commands only run when a valid context is available
- **sdk_cmd_opt_safely()**: Implementation of the `--safely` option that runs commands in the SDK container

### Environment Management

- **sdk_boo_env_setup_environment()**: Sets up all environment variables for the SDK
  ```bash
  # Excerpt of what this function does:
  # - Sources all utility modules for environment setup
  # - Stores original environment state (args, working directory)
  # - Computes and defines critical paths and directories
  # - Detects container state, git repository info, version info
  # - Validates the environment is properly configured
  ```
- **sdk_boo_env_uti_cli_auto_discovery()**: Automatically discovers the context directory by looking for the `cli` file
- **sdk_boo_env_uti_get_git_dir()**: Locates the git directory for the context, handling submodules
- **sdk_boo_env_uti_is_in_container()**: Detects if the SDK is running in a container
- **sdk_boo_env_uti_validate_environment()**: Validates that required directories and files exist

## Lifecycle Hooks

The SDK provides a hook system through `bootstrap/hooks.sh` that allows projects to extend functionality at key points in the execution lifecycle:

### Hook Implementation

- **handle_hook()**: The core function that executes hooks in the context

### Hook Types

Hooks can be defined in the context's `cli` file for events like:

- **hook:before_install**: Before installation process begins
- **hook:after_install**: After installation completes
- **hook:before_update**: Before updating the SDK
- **hook:after_update**: After updating the SDK
- **hook:before_push**: Before pushing changes to the repository
- **hook:after_push**: After pushing changes to the repository

## How It All Works Together

1. **Initialization**:
   - When a command is executed, the context's `cli` file sources the SDK's `index.sh`
   - `index.sh` loads shared utilities and bootstraps the environment
   - Environment variables are set up to define paths, state, and capabilities

2. **Command Routing**:
   - The context's `cli` file handles custom commands or passes standard commands to the SDK
   - The SDK's `cli.sh` routes commands to appropriate facades or internal commands
   - Commands are executed in the appropriate environment (container or host)

3. **Facade Execution**:
   - Each facade provides its own CLI interface via `facades/*/cli.sh`
   - Facades implement specific functionality (git, docker, etc.) with a consistent interface
   - Facades may call other facades through the `cli_ctx` function

4. **Container Execution**:
   - The `safely` function ensures commands run in the SDK container
   - Container execution provides consistency across different environments
   - Environment variables are preserved and passed to the container

## Extending the SDK

Projects can extend the SDK by:

1. Creating a `cli` file at the root of the project
2. Sourcing the SDK's `index.sh` to initialize the environment
3. Implementing custom commands in the `cli` file's command router
4. Using `cli_ctx` to call standard SDK commands or other custom commands

Example `cli` file:

```bash
#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/node_modules/@diseec/sdk/index.sh"

c=$1; shift; case $c in
    # Custom command implementation
    custom)
        # Custom command logic here
        cli_ctx format # Call standard SDK command
    ;;

    # Override standard command
    format)
        cli_core format "**/*.{js,jsx,ts,tsx,json,css,scss,md}"
    ;;

    # Default to SDK commands
    *) cli_core $c "$@" ;;
esac
```

## Best Practices

1. **Use `cli_ctx` for command execution**: Always use `cli_ctx` to ensure commands run in the proper context
2. **Use `safely` for container execution**: Use `safely` to ensure consistent execution environments
3. **Validate context when needed**: Use `mark_ctx_only` to ensure commands only run in a valid context
4. **Source files only once**: Use `source_once` to prevent duplicate initialization
5. **Extend rather than replace**: Build on the SDK's capabilities rather than replacing them

## Conclusion

The DISEEC SDK provides a powerful and flexible foundation for project automation and standardization. Its modular architecture, context-based command routing, and container-based execution model ensure consistent development experiences across different projects while allowing for customization and extension.
