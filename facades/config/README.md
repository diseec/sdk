# Centralized Configuration System

# Scope Overview

**Repository Scope**: Acts as the main scope for configuration, providing repository-specific settings that take precedence. This is where most configuration is managed for a given project.

**User Scope**: Used for common settings that a user wants to share across multiple repositories. These preferences are personal and portable between projects.

**Context Scope**: Stores configuration that is burned into the repository itself and is version controlled. This ensures that certain settings are tracked and shared with all collaborators via version control.

This document describes the new centralized configuration management system that replaces the old scattered configuration handling across multiple facades.

## Overview

The new configuration system provides:

- **Hierarchical Configuration**: Multiple configuration scopes with clear precedence
- **Unified API**: Single interface for all configuration operations
- **Backward Compatibility**: Existing code continues to work during transition
- **Extensible Structure**: Easy to add new configuration types and scopes
- **Migration Tools**: Automated migration from old configuration files

## Configuration Hierarchy

Configuration values are resolved in this order of precedence (highest to lowest):

1. **Project** (`.sdk/project.yaml`) - Project-specific overrides
2. **Workspace** (`$D_ORG_DIR/workspaces/$D_REPO_NAME/workspace.yaml`) - Repository-specific settings
3. **User** (`$D_ORG_DIR/users/$USER/user.yaml`) - User-specific preferences
4. **Global** (`$D_ORG_DIR/config.yaml`) - Organization-wide defaults

## File Structure

```
$D_ORG_DIR/
├── config.yaml                           # Global configuration
├── users/
│   └── $USER/
│       └── user.yaml                      # User configuration
└── workspaces/
    └── $D_REPO_NAME/
        └── workspace.yaml                 # Workspace configuration

$D_CTX_DIR/
└── .sdk/
    └── project.yaml                       # Project configuration
```

## Configuration File Examples

### Global Configuration (`$D_ORG_DIR/config.yaml`)

```yaml
version: "1.0"
organization:
  name: diseec
  registry: registry.diseec.com
defaults:
  shell: bash
  editor: code
```

### Workspace Configuration (`$D_ORG_DIR/workspaces/$D_REPO_NAME/workspace.yaml`)

```yaml
workspace:
  submodules:
    - service-a
    - service-b
  services:
    - api
    - frontend
environment:
  development:
    database_url: localhost:5432
  staging:
    database_url: staging.example.com:5432
  production:
    database_url: prod.example.com:5432
```

### User Configuration (`$D_ORG_DIR/users/$USER/user.yaml`)

```yaml
user:
  preferences:
    theme: dark
    timezone: UTC-8
    editor: vim
```

### Project Configuration (`$D_CTX_DIR/.sdk/project.yaml`)

```yaml
project:
  type: nodejs
  build:
    commands:
      - npm install
      - npm run build
  deploy:
    targets:
      - staging
      - production
```

## API Reference

### Core Functions

#### `sdk_fac_con_get <key.path> [scope]`

Get configuration value with hierarchy resolution

```bash
sdk_fac_con_get "organization.name"           # Returns from highest precedence scope
sdk_fac_con_get "workspace.submodules" workspace  # Get only from workspace scope
```

#### `sdk_fac_con_set <key.path> <value> [scope]`

Set configuration value in specified scope (defaults to workspace)

```bash
sdk_fac_con_set "defaults.shell" "zsh" global
sdk_fac_con_set "workspace.version" "2.0"         # Sets in workspace scope
```

#### `sdk_fac_con_delete <key.path> [scope]`

Delete configuration key from specified scope

```bash
sdk_fac_con_delete "old.setting" workspace
```

### Array and Object Operations

Arrays and objects should be set using JSON format with the `sdk_fac_con_set` function:

```bash
# Set an array
sdk_fac_con_set "workspace.submodules" '["service1", "service2"]'

# Set an object
sdk_fac_con_set "user.preferences" '{"theme": "dark", "notifications": true}'
```

To remove array items or modify arrays, use the `set` command with a new JSON array:

```bash
# Remove an item by setting a new array without that item
sdk_fac_con_set "workspace.submodules" '["service1"]'  # removes "service2"
```

### Introspection

#### `sdk_fac_con_which <key.path>`

Show configuration value resolution path

```bash
sdk_fac_con_which "defaults.shell"
# Output:
# Configuration resolution for 'defaults.shell':
#   ✔ [project] zsh (ACTIVE)
#   - [workspace] (not set)
#   - [user] bash (overridden)
#   - [global] bash (overridden)
```

#### `sdk_fac_con_list_keys [scope]`

List all configuration keys

```bash
sdk_fac_con_list_keys workspace    # List keys from workspace scope
sdk_fac_con_list_keys              # List keys from all scopes
```

#### `sdk_fac_con_print [scope]`

Print configuration for scope or all scopes

```bash
sdk_fac_con_print workspace        # Print workspace configuration
sdk_fac_con_print                  # Print all configurations
```

## CLI Usage

The configuration system provides a CLI interface:

```bash
# Get configuration values
config get organization.name
config get workspace.submodules workspace

# Set configuration values
config set defaults.editor vim global
config set workspace.version "2.0"

# Array operations
config array-add workspace.submodules new-service
config array-remove workspace.submodules old-service

# Introspection
config which defaults.shell
config list workspace
config print

# Migration
config migrate                 # Migrate from old configuration structure
config cleanup                # Clean up old configuration files
```

## Legacy Configuration (Still Supported)

### Secrets Management

The sdk encrypts sensitive data like API keys using AES-256-CBC encryption. This is essential for AI-powered features.

**Setting Up Secrets:**

1. **Initialize secrets system:**

   ```bash
   D secret init
   ```

2. **Add your OpenAI API key:**

   ```bash
   D secret add
   ```

3. **Load secrets into environment:**
   ```bash
   source D secret get
   ```

### Legacy Workspace Management

For monorepos with git submodules, workspace lets you select which modules to work with.

**Daily Usage:**

- **Check current selection:** `D workspace status`
- **Change selection:** `D workspace select`
- **Start selected services:** `D dev`

## Migration from Legacy System

### Automatic Migration

Run the migration command to automatically convert old configuration files:

```bash
config migrate
```

This will:

1. Backup existing configuration files
2. Convert old global configuration to new organized structure
3. Migrate workspace configurations to new format
4. Create user and project configuration files with defaults

### Manual Migration

For complex configurations, you may need to manually review and adjust:

1. Check what will be migrated:

   ```bash
   config print all
   ```

2. Review old configuration files:

   ```bash
   cat $D_ORG_DIR/config.yaml
   cat $D_ORG_DIR/workspaces/$D_REPO_NAME/config.yaml
   ```

3. Migrate specific values:
   ```bash
   config set organization.name "diseec" global
   config array-add workspace.submodules "my-service"
   ```

## Backward Compatibility

The system maintains backward compatibility through wrapper functions:

## Configuration Storage

- **Global config:** `~/.diseec/config.yaml` (organization defaults, encryption keys)
- **User config:** `~/.diseec/users/$USER/user.yaml` (personal preferences)
- **Workspace config:** `~/.diseec/workspaces/[repo-name]/workspace.yaml` (module selection)
- **Project config:** `.sdk/project.yaml` (local project settings)
- **Encrypted secrets:** `./secrets/` (encrypted files in your project)
