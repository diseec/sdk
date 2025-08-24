# Installation Guide

> **Setup DISEEC DevOps Kit for your project**

## Prerequisites

- **Docker** (20.10+) - Container orchestration
- **Git** (2.20+) - Version control
- **Node.js** (16+) - For npm installation
- **Bash** (4.0+) - Shell compatibility

### Optional Dependencies

- **GitHub CLI** (`gh`) - Enhanced git workflow features
- **yq** - Advanced YAML configuration management
- **OpenAI API Key** - AI-powered git commit messages

## Installation

### Step 1: Install Package

```bash
# Install globally (required)
npm install -g @diseec/kit

# Install in project (required)
npm install @diseec/kit --save-dev
```

### Step 2: Initialize Project

```bash
# Initialize project (copies templates including customizable cli)
D install
```

This creates:

- `cli` file - Customizable project CLI
- `.diseec/` directory - Configuration and secrets
- Template files for customization

### Step 3: Create Required Docker Files

**REQUIRED**: Create these Docker files manually for the kit to work:

1. **Dockerfile** (production-ready):

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# REQUIRED: Set container environment variable for DISEEC kit compatibility
ENV IS_IN_CONTAINER=true

EXPOSE 3000
CMD ["npm", "start"]
```

2. **docker-compose.yaml** (production):

```yaml
services:
  my-project: # Must match repository name
    build:
      context: ${ROOT_DIR}
    ports:
      - 80:3000
```

3. **docker-compose.override.yaml** (development):

```yaml
services:
  my-project: # Must match repository name
    volumes:
      - .:/app
    command: npm run dev
```

**Important**: The main service name must match your project repository name.

### Step 4: Verify Installation

```bash
# Check CLI is working
D help
D version
D status
```

## Project Structure

After installation:

```
~/.diseec/
project/
├── cli                    # Customizable project CLI
│   ├── config.yaml       # Project configuration
│   └── secrets.encrypted # Encrypted secrets (auto-created)
├── node_modules/
│   └── @diseec/kit/      # Kit installation
└── package.json          # With @diseec/kit dependency
```

## CLI Customization

The project `cli` file allows full customization:

```bash
# Example: Override install command
install() {
    echo "Installing project dependencies..."
    npm install
    $CLI_BASE install  # Call original install command
}

```

Variables available:

- `$CLI_BASE` - Call original kit commands
- `$CLI` - Call the project cli itself

## Optional Setup

### Initialize Secrets

```bash
D secret init
D secret add  # Add secret interactively
```

### Configure Workspace

```bash
D workspace init  # For multi-module projects
```

### Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@diseec.com"
```

## Platform-Specific Notes

### macOS

```bash
brew install docker git node
npm install -g @diseec/kit
```

### Ubuntu/Debian

```bash
sudo apt install docker.io git nodejs npm
sudo usermod -aG docker $USER
npm install -g @diseec/kit
```

### Windows (WSL2)

```bash
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu
# Follow Ubuntu instructions inside WSL2
```

## Verification

```bash
# Test core functionality
D help
D version
D status
D docker version
D git _status
```

## Troubleshooting

### Permission Issues

```bash
chmod +x cli
sudo usermod -aG docker $USER  # Linux
```

### Command Not Found

```bash
# Check global installation
npm list -g @diseec/kit
which D
```

### Docker Issues

```bash
# Start Docker service
sudo systemctl start docker  # Linux
# Or start Docker Desktop (macOS/Windows)
```

## Next Steps

1. **[Configure Project](CONFIGURATION.md)** - Setup project configuration
2. **[Setup Secrets](SECRETS.md)** - Configure secure credential storage
<!-- 3. **[Git Workflows](GIT-WORKFLOWS.md)** - Master automated git operations -->
