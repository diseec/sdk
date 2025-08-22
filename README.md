# DISEEC DevOps Kit

> **Enterprise-grade DevOps automation toolkit for modern development workflows**

[![Version](https://img.shields.io/badge/version-latest-blue)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](#license)
[![Internal Use](https://img.shields.io/badge/access-internal%20only-red)](#)

## Overview

The DISEEC DevOps Kit is a comprehensive automation toolkit designed to standardize and streamline development workflows across projects. It provides a unified CLI interface, container orchestration, secrets management, and project lifecycle automation for teams building modern applications.

### Key Features

- 🚀 **Unified CLI Interface** - Single command interface for all development operations
- 🐳 **Container Orchestration** - Docker and Docker Compose automation
- 🔐 **Secure Secrets Management** - AES-256 encrypted secrets with automatic key generation
- 🌊 **Git Workflow Automation** - AI-powered commit messages and PR management
- 📦 **Package & Service Management** - Automated submodule and dependency management
- ⚙️ **Workspace Configuration** - Personalized development environment setup
- 🧪 **Testing Automation** - Health checks, unit, integration, and E2E testing
- 🔧 **Infrastructure as Code** - Standardized project templates and configurations

## Quick Start

### Installation

```bash
# Install in your project
npm install --save-dev @diseec/kit

# Create CLI entrypoint
echo '#!/bin/bash\n. ./node_modules/@diseec/kit/index.sh' > cli
chmod +x cli

# Initialize project
./cli install
```

### Basic Usage

```bash
# Start development environment
./cli dev

# Run tests
./cli test

# Build and deploy
./cli build

# Get help for any command
./cli help
./cli git help
./cli secrets help
```

## Documentation

### Core Guides

| Guide                                       | Description                                            |
| ------------------------------------------- | ------------------------------------------------------ |
| [CLI Reference](docs/CLI-REFERENCE.md)      | Complete command reference and usage examples          |
| [Installation Guide](docs/INSTALLATION.md)  | Detailed setup instructions for different environments |
| [Configuration](docs/CONFIGURATION.md)      | Project and workspace configuration options            |
| [Development Workflow](docs/DEVELOPMENT.md) | Day-to-day development operations                      |

### Feature Documentation

| Feature                                   | Documentation                              |
| ----------------------------------------- | ------------------------------------------ |
| [Secrets Management](docs/SECRETS.md)     | Secure credential storage and management   |
| [Git Workflows](docs/GIT-WORKFLOWS.md)    | Automated git operations and PR management |
| [Docker Integration](docs/DOCKER.md)      | Container orchestration and deployment     |
| [Testing Framework](docs/TESTING.md)      | Automated testing strategies and setup     |
| [Workspace Management](docs/WORKSPACE.md) | Multi-module project configuration         |

### Advanced Topics

| Topic                                      | Documentation                               |
| ------------------------------------------ | ------------------------------------------- |
| [Custom Commands](docs/EXTENDING.md)       | Adding custom commands and integrations     |
| [CI/CD Integration](docs/CICD.md)          | Continuous integration and deployment setup |
| [Style Guide](docs/STYLE-GUIDE.md)         | CLI styling and color conventions           |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and solutions                 |

## Project Structure

```
kit/
├── src/                    # Core CLI implementation
│   ├── cli.sh             # Main CLI entry point
│   ├── core/              # Core utilities (env, output, wrappers)
│   ├── cmds/              # Command implementations
│   ├── facades/           # High-level API facades
│   └── informs/           # Information and validation scripts
├── templates/             # Project templates and scaffolding
├── docs/                  # Comprehensive documentation
├── legacy/               # Legacy scripts (deprecated)
└── index.sh              # Kit initialization script
```

## Command Categories

### Project Management

- `install` - Install dependencies and setup tools
- `update` - Update CLI and sync project
- `status` - Show comprehensive project status

### Development Environment

- `dev` - Start development environment
- `build` - Build project images
- `run` - Execute commands in containers
- `test` - Run test suites
- `format` - Format codebase

### Source Control

- `git` - Git workflow management
- `pull` - Pull and merge latest changes
- `push` - Auto-commit and create PR

### Infrastructure

- `docker` - Docker operations
- `service` - Service management
- `package` - Package management
- `workspace` - Workspace configuration

### Configuration & Security

- `config` - Configuration management
- `secrets` - Encrypted secrets management
- `env` - Environment variables

## Examples

### Development Workflow

```bash
# Setup new project
./cli install project
./cli workspace init

# Daily development
./cli dev                    # Start development environment
./cli test health           # Quick health check
./cli format                # Format code

# Git workflow with AI
./cli git status            # Check PR status
./cli git push              # Auto-commit with AI message and create PR
```

### Secrets Management

```bash
# Initialize secrets (first time)
./cli secrets init

# Add secrets interactively
./cli secrets add
# Enter: OPENAI_API_KEY
# Value: sk-your-key-here

# Export to environment
source <(./cli secrets get-all)

# Use in development
./cli git push              # Uses OPENAI_API_KEY for AI commits
```

### Container Operations

```bash
# Container lifecycle
./cli docker compose up-development    # Start services
./cli shell                           # Interactive shell
./cli run npm test                    # Execute commands
./cli docker compose down            # Stop services
```

## Requirements

- **Docker** - Container orchestration
- **Git** - Version control
- **Bash 4.0+** - Shell compatibility
- **Node.js 16+** - For npm installation (optional)

### Optional Dependencies

- **GitHub CLI** (`gh`) - Enhanced git workflow features
- **yq** - Advanced YAML configuration management
- **OpenAI API Key** - AI-powered git commit messages

## Contributing

This is an internal DISEEC tool. For contributions:

1. Follow the [Style Guide](docs/STYLE-GUIDE.md)
2. Add tests for new features
3. Update documentation
4. Submit internal PR for review

## Security

- 🔐 All secrets encrypted with AES-256-CBC
- 🛡️ Auto-generated encryption keys
- 🚫 No plaintext credential storage
- ✅ Internal use only - do not distribute

## License

MIT License - Internal DISEEC use only. See [LICENSE](LICENSE) for details.

## Support

- **Documentation**: Check the [docs/](docs/) directory
- **Issues**: [GitHub Issues](https://github.com/diseec/kit/issues)
- **Team**: Contact DISEEC DevOps team

---

**Made with ❤️ by DISEEC Engineering**
