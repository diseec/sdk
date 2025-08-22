# Secrets Manager Usage Examples

## Quick Start

1. **Initialize the secrets manager** (first time only):

   ```bash
   ./cli secrets set-password
   ```

2. **Add your OpenAI API key**:

   ```bash
   ./cli secrets add
   # Enter secret name: OPENAI_API_KEY
   # Enter secret value: sk-your-api-key-here
   ```

3. **Source all secrets into your environment**:

   ```bash
   eval "$(./cli secrets get-all)"
   ```

4. **Verify secrets are loaded**:
   ```bash
   echo $OPENAI_API_KEY
   ```

## Common Commands

### Password Management

```bash
# Set initial password (first time)
./cli secrets set-password

# Reset password (requires current password)
./cli secrets reset-password
```

### Secret Management

```bash
# Add a new secret
./cli secrets add

# List all secret names
./cli secrets list

# Export all secrets
./cli secrets get-all

# Remove a secret
./cli secrets remove SECRET_NAME
```

### Integration with Git AI Features

Once you've added your `OPENAI_API_KEY` secret, the git commands will automatically use it for AI-generated commit messages:

```bash
# This will use AI if OPENAI_API_KEY is available
./cli git push
```

### Sourcing Secrets in Scripts

To automatically source secrets in your environment scripts:

```bash
# Add to your shell profile or script
eval "$(./cli secrets get-all 2>/dev/null || true)"
```

## Security Features

- **AES-256-CBC encryption** with PBKDF2 key derivation (100,000 iterations)
- **Master password protection** with SHA-256 hashing
- **Salt-based encryption** for each secret
- **No plaintext storage** - all secrets are encrypted at rest
- **Secure password input** - passwords are not echoed to terminal

## File Locations

- **Config**: `$ROOT_DIR/.kit/config.yaml` (password hash)
- **Secrets**: `$KIT_SRC_DIR/secrets/` (encrypted secret files)

## Example Workflow

```bash
# Initial setup
./cli secrets set-password

# Add common secrets
./cli secrets add  # OPENAI_API_KEY
./cli secrets add  # DATABASE_URL
./cli secrets add  # API_TOKEN

# Use in scripts
eval "$(./cli secrets get-all)"
./cli git push  # Will use OPENAI_API_KEY for AI commit messages

# List what's stored
./cli secrets list
```
