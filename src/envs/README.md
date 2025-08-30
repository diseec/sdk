# Environment System Documentation

## Overview

The environment system has been reorganized into a modular structure for better maintainability, testability, and clarity. The original monolithic `envs.sh` file has been split into focused modules.

## Structure

```
packages/kit/src/core/
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
  - `env_uti_cli_auto_discovery()`: Finds the project root
  - `get_org_dir()`: Gets/creates organization directory
  - `get_cache_dir()`: Gets/creates cache directory
- **Benefits**: Isolated path logic, easier to test and debug

### 3. Git Utilities (`utils/git-utils.sh`)

- **Purpose**: Git-related operations without using git commands
- **Contents**:
  - `env_uti_get_git_config_file()`: Locates git config file
  - `env_uti_get_repo_url()`: Extracts repository URL
  - `env_uti_get_repo_name()`: Extracts repository name
  - `env_uti_get_current_branch()`: Gets current branch name
- **Benefits**: Git operations work even when git is not available

### 4. Environment Detection (`utils/env_detection.sh`)

- **Purpose**: Detect various environment states
- **Contents**:
  - `env_uti_is_in_container()`: Container environment detection
  - `env_uti_has_submodules()`: Git submodules detection
  - `env_uti_get_kit_version()`: Extract kit version from package.json
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
source /path/to/envs.sh
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

- `ORG_NAME`, `KIT_NAME`, `TARGET_MOUNTED_DIR`
- `IMAGE_REGISTRY_URL`, `KIT_IMAGE`, `REPO_HUB_URL`, `KIT_RELATIVE_PATH`

### Computed Paths

- `ROOT_DIR`, `KIT_SRC_DIR`, `cli_main`, `cli_core`
- `ORG_DIR`, `ORG_CACHE_DIR`

### Environment State

- `IS_IN_CONTAINER`, `HAS_SUBMODULES`
- `VERSION`, `REPO_URL`, `REPO_NAME`, `CURRENT_BRANCH`

## Validation

Use the `env_uti_validate_environment` function to check if the environment is properly set up:

```bash
if ! env_uti_validate_environment; then
    echo "Environment validation failed"
    exit 1
fi
```
