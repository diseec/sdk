# Configuration

This guide covers the two main configuration systems you need to use the kit effectively.

## Secrets Management

The kit encrypts sensitive data like API keys using AES-256-CBC encryption. This is essential for AI-powered features.

### Why You Need OPENAI_API_KEY

The kit uses OpenAI to generate intelligent commit messages when you run `D git push`. Without this key, you'll get basic commit messages instead of AI-generated ones.

### Setting Up Secrets

1. **Initialize secrets system:**

   ```bash
   D secret init
   ```

   This auto-generates an encryption key and stores it in your config.

2. **Add your OpenAI API key:**

   ```bash
   D secret add
   ```

   - Enter `OPENAI_API_KEY` as the name
   - Paste your OpenAI API key as the value

3. **Load secrets into environment:**
   ```bash
   source D secret get
   ```

### Daily Usage

- **View secret:** `D secret show`
- **List secret names:** `D secret list`
- **Remove a secret:** `D secret remove OPENAI_API_KEY`

The encryption key is stored in `~/.diseec/config.yaml`. Keep it safe - you need it to decrypt your secrets.

## Workspace Management

For monorepos with git submodules, workspace lets you select which modules to work with.

### Why Use Workspace

Instead of starting all services in a monorepo, workspace lets you:

- Select only the modules you're actively developing
- Reduce resource usage and startup time
- Coordinate related services together

### Setting Up Workspace

1. **Initialize workspace configuration:**

   ```bash
   D workspace init
   ```

2. **Select modules to work with:**
   ```bash
   D workspace select
   ```
   Choose from available submodules by number or type `all`.

### How It Works

The workspace system:

- Reads your `.gitmodules` file to find available modules
- Stores your selection in `~/.diseec/workspaces/[repo-name]/config.yaml`
- Only starts selected services when you run `D dev`
- Coordinates git operations across selected modules

### Daily Usage

- **Check current selection:** `D workspace status`
- **Change selection:** `D workspace select`
- **Start selected services:** `D dev`

## Configuration Storage

- **Global config:** `~/.diseec/config.yaml` (encryption keys, global settings)
- **Workspace config:** `~/.diseec/workspaces/[repo-name]/config.yaml` (module selection)
- **Encrypted secrets:** `./secrets/` (encrypted files in your project)

The kit automatically creates these directories and files as needed.
