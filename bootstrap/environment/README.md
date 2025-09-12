# Environment System Documentation

## Overview

The environment system has been reorganized into a modular structure for better maintainability, testability, and clarity. The original monolithic `envs.sh` file has been split into focused modules.

## Structure

```
packages/sdk/bootstrap/
├── envs.sh                     # Main entry point
├── config/
│   └── constants.sh           # Organization and project constants
└── utils/
    ├── path-discovery.sh      # Path and directory discovery functions
    ├── git-utils.sh          # Git repository operations
    └── env_detection.sh      # Environment state detection
```

## Modules

### 1. Constants (`config/constants.sh`)

- **Purpose**: Define immutable organizational and project constants
- **Contents**:
  - Organization name and project identifiers
  - Registry URLs and repository configurations
  - Mount directories and relative paths
- **Benefits**: Central location for configuration that rarely changes

### 2. Path Discovery (`utils/path-discovery.sh`)

- **Purpose**: Functions for discovering project structure and paths
- **Contents**:
  - `sdk_boo_env_uti_cli_auto_discovery()`: Finds the project root
  - `sdk_boo_env_uti_get_org_dir()`: Gets/creates organization directory
  - `sdk_boo_env_uti_get_cache_dir()`: Gets/creates cache directory
- **Benefits**: Isolated path logic, easier to test and debug

### 3. Git Utilities (`utils/git-utils.sh`)

- **Purpose**: Git-related operations without using git commands
- **Contents**:
  - `sdk_boo_env_uti_get_git_config_file()`: Locates git config file
  - `sdk_boo_env_uti_get_repo_url()`: Extracts repository URL
  - `sdk_boo_env_uti_get_repo_name()`: Extracts repository name
  - `sdk_boo_env_uti_get_current_branch()`: Gets current branch name
- **Benefits**: Git operations work even when git is not available

### 4. Environment Detection (`utils/env_detection.sh`)

- **Purpose**: Detect various environment states
- **Contents**:
  - `sdk_boo_env_uti_is_in_container()`: Container environment detection
  - `sdk_boo_env_uti_has_submodules()`: Git submodules detection
  - `sdk_boo_env_uti_get_kit_version()`: Extract sdk version from package.json
- **Benefits**: Clear separation of concerns, reusable functions

### 5. Main Environment (`envs.sh`)

- **Purpose**: Load all modules and initialize environment variables
- **Contents**:
  - Module loading and sourcing
  - Variable computation and initialization
  - Environment validation
  - Variable exports
- **Benefits**: Clean orchestration of all environment setup

## Key Improvements

### 1. **Modularity**

- Each module has a single responsibility
- Functions are logically grouped
- Easier to maintain and extend

### 2. **Readability**

- Clear section headers and documentation
- Consistent function naming conventions
- Logical flow from constants to computed values

### 3. **Error Handling**

- Better error messages with context
- Validation function to check environment state
- Graceful handling of missing directories/files

### 4. **Performance**

- Functions only called when needed
- Reduced redundant operations
- Caching of expensive operations

### 5. **Security**

- Use of `readonly` for immutable variables
- Proper quoting to prevent word splitting
- Shellcheck-compatible code

### 6. **Testability**

- Functions can be tested independently
- Clear input/output contracts
- Isolated dependencies

## Usage

The main `envs.sh` file is still the single entry point:

```bash
source /path/to/environment.sh
```

All environment variables are automatically exported and available to child processes.

## Migration Notes

- All existing environment variables remain available
- Function names have been improved for clarity
- Added validation function for environment checking
- Removed commented-out legacy code

## Environment Variables

All variables are exported and available:

### Constants

- `D_ORG_NAME`, `D_SDK_NAME`, `D_CONT_CTX_DIR`
- `D_REGISTRY_URL`, `D_SDK_IMAGE`, `D_REPOSITORY_URL`, `D_SDK_LOCAL_RELATIVE_PATH`

### Computed Paths

- `D_CTX_DIR`, `D_SDK_DIR`, `cli_ctx`, `cli_core`
- `D_ORG_DIR`, `D_ORG_CACHE_DIR`

### Environment State

- `D_IS_IN_CONTAINER`, `D_HAS_SUBMODULES`
- `D_VERSION`, `D_REPO_URL`, `D_REPO_NAME`, `D_CURRENT_BRANCH`

## Validation

Use the `sdk_boo_env_uti_validate_environment` function to check if the environment is properly set up:

```bash
if ! sdk_boo_env_uti_validate_environment; then
    echo "Environment validation failed"
    exit 1
fi
```
