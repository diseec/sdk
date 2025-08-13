# @diseec/devops

> Enterprise DevOps Toolkit for DISEEC Monorepos

---

## Overview

`@diseec/devops` is a comprehensive, enterprise-grade DevOps toolkit designed to standardize, automate, and streamline development, CI/CD, and deployment workflows across DISEEC projects. It provides reusable CLI scripts, Dockerfiles, configuration templates, and submodule management utilities for modern monorepo environments.

Currently distributed as an npm package, it can be installed in any Node.js project and activated by creating a CLI entrypoint in your project root. Future releases will support additional languages and ecosystems for cross-platform DevOps automation.

---

## Features

- **Unified CLI**: Project-level command-line interface for all common DevOps and automation tasks.
- **Submodule Management**: Add, remove, update services and packages as git submodules with safety prompts and branch management.
- **Environment Detection**: Auto-detects project root, repository info, and environment variables for consistent operations.
- **Docker Integration**: Ready-to-use Dockerfiles and build/push scripts for containerized workflows.
- **CI/CD Templates**: Includes workflow templates for GitHub Actions and other CI/CD systems.
- **Health & Test Automation**: Built-in health checks, E2E, and smoke test runners.
- **Extensible Architecture**: Modular shell scripts for easy extension and customization.

---

## Getting Started

### Prerequisites

- Docker
- Git
- Bash/SH compatible shell
- Node.js (for npm installation)

### Installation (Node.js projects)

Add `@diseec/devops` to your project:

```sh
npm install --save-dev @diseec/devops
# or
yarn add -DW @diseec/devops
```

Create a CLI entrypoint in your project root (e.g., `cli`):

```sh
#!/bin/sh
. ./node_modules/@diseec/devops/common/cli.sh
```

Run the CLI for available commands:

```sh
sh cli --help
```

Typical workflow:

```sh
sh cli install      # Install dependencies and submodules
sh cli dev          # Start development server
sh cli test         # Run tests
sh cli build        # Build and push Docker images
sh cli release      # Release workflow
```

---

## CLI Commands

- `install` : Install dependencies, initialize submodules, and set up branches
- `status` : Show branch and environment status
- `pull` : Pull and merge latest changes from remote
- `dev` : Start development environment
- `pro` : Start production environment
- `build` : Build and push Docker images
- `run` : Run arbitrary commands in Docker
- `exec` : Execute commands in running containers
- `shell` : Open a shell in Docker
- `test` : Run health, smoke, unit, or E2E tests
- `release` : Merge and push release branches
- `kit` : Manage project kits
- `service` : Add/remove/update service submodules
- `package` : Add/remove/update package submodules
- `workspace` : Manage developer workspace module selection
  - `init` : Initialize workspace configuration
  - `select` : Select modules for your workspace
  - `status` : Show current workspace configuration
  - `sync` : Sync workspace with latest devops tool updates
- `help` : Display help message---

## Workspace Configuration

The DevOps toolkit now supports personalized workspace configurations through the workspaces cli. This feature allows team members to select which modules they want to work with, streamlining development by only cloning, installing, and updating the modules relevant to their work.

### How It Works

1. When running `cli install` for the first time, you'll be prompted to select which modules you want to include in your workspace.
2. Selected modules are saved to `~/diseec/workspaces/REPO_NAME.yaml` in your project root.
3. Subsequent commands like `install`, `pull`, `dev`, and `pro` will only operate on your selected modules.

### Managing Your Workspace

```sh
# Initialize or reinitialize your workspace configuration
sh cli workspace init

# Change which modules are included in your workspace
sh cli workspace select

# View your current workspace configuration
sh cli workspace status
```

### Example Workspace Configuration

```yaml
modules:
  - d0-www
  - d0-cms
  # - ai-panel (commented out means not included)
```

This means operations will only be performed on the d0-www and d0-cms modules, while ai-panel will be ignored.

### Version Syncing

The workspace system includes an automatic version tracking mechanism that helps keep all repositories in sync with the latest devops tool updates:

```sh
# Check and apply updates from the latest devops version
sh cli workspace sync

# Run custom commands during sync (for project-specific updates)
sh cli workspace sync "npm install -g typescript" "echo 'Custom sync complete'"

# Sync multiple commands with line continuation
D workspace sync \
  D install; \
  D pull;
```

The sync command:

1. Checks if the current devops version differs from the cached version
2. Runs necessary update steps for the new version
3. Executes any custom commands you provide
4. Updates the cached version

This ensures that all team members can easily stay up-to-date with tooling changes.

---

## Architecture

**common/bin/**: Modular shell scripts for commands, helpers, environment detection, and submodule management.
**common/cli.sh**: Main CLI entrypoint, sources all helpers and command modules.
**Dockerfile**: Reference Dockerfile for building and running toolkit in containers.
**templates/**: Example templates for Next.js and other frameworks, including CLI and Docker setup.

## Roadmap

- **Multi-language support**: Planned future support for Python, Go, and other ecosystems.
- **Cross-platform CLI**: Unified DevOps commands for any project type.
- **Extensible plugin system**: Add custom scripts and integrations for your stack.

Stay tuned for updates as we expand beyond Node.js and npm.

---

## Security & Compliance

- Internal use only. Do not distribute outside DISEEC.
- All scripts prompt for confirmation before destructive actions.
- Sensitive operations (e.g., submodule removal) require explicit user approval.

---

## Extending & Customizing

- Add new commands by extending `common/bin/cmds.sh` and sourcing in `cli.sh`.
- Use environment detection in `envs.sh` for robust root/project location.
- Integrate with CI/CD by using provided workflow templates and Dockerfiles.

---

## Support & Contribution

- For issues, use [GitHub Issues](https://github.com/diseec/devops/issues)
- For feature requests, contact the DISEEC DevOps team.
- Contributions are welcome for internal improvements only.

---

## License

MIT (Internal Use Only)
