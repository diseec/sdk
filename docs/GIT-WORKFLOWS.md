# Git Workflows

> **AI-powered git automation with PR management and smart commit messages**

The DISEEC Kit provides intelligent git workflow automation that streamlines the entire development cycle from commit to PR creation with AI-generated commit messages and automated PR management.

## Core Commands

### Quick Actions

```bash
# Most common workflow - commit all changes, push, and create PR
D push                    # Alias for _commit-push-pr
D git pus                 # Full command

# Check current PR status and unresolved comments
D git _status             # Shows PR status, reviews, and comments

# Pull latest changes and merge with main
D pull                    # Alias for _pull
D git pul                 # Full command
```

### Advanced Git Commands

```bash
# Individual operations
D git pre                 # Create PR only (no commit/push)
D git che                 # Checkout/create branch interactively
D git cml                 # Get commit report _status
D git rel                 # Create release tag (dev only)

# Recursive operations (monorepos)
D push --recursive        # Run on all selected submodules
D pull --recursive        # Pull/merge in all submodules
```

## Key Features

### AI-Powered Commit Messages

- **OpenAI Integration**: Uses GPT-3.5-turbo for intelligent commit messages
- **Smart Fallback**: Generates descriptive messages when API unavailable
- **Context Aware**: Analyzes diff content and file changes
- **Automatic Staging**: Stages all changes automatically

**Requirements**: Set `OPENAI_API_KEY` in secrets (`D secret add`)

### Automated PR Management

- **Auto PR Creation**: Creates PRs with commit message as title/body
- **GitHub CLI Integration**: Full PR management via `gh` CLI
- **Status Checking**: Shows review status, comments, and approval state
- **Smart Detection**: Finds existing PRs for current branch

### Safety Features

- **Main Branch Protection**: Requires confirmation for direct main commits
- **Detached HEAD Detection**: Auto-switches to proper branch
- **Change Validation**: Only commits/pushes when changes exist
- **Conflict Prevention**: Checks for uncommitted/unpushed changes

### Comprehensive Reporting

After successful operations, get a detailed report:

```
DATE 2025-08-24
DEVE Your Name
EMAI your.email@domain.com
REPO repository-name
BRAN feature-branch
COMM https://github.com/org/repo/commit/abc123
PULL https://github.com/org/repo/pull/42

AI-generated commit message with details

Modified files:
 src/components/Header.tsx | 12 ++++++------
 docs/README.md           |  8 ++++++++
```

## Workflow Examples

### Standard Development Cycle

```bash
# 1. Create feature branch (auto-detects username from git email)
D git che
# Enter: feature-name (or press enter for username)

# 2. Make your changes...

# 3. Check status before committing
D git _status
# Shows: Current PR status, pending reviews, unresolved comments

# 4. Commit, push, and create PR in one command
D push
# - Stages all changes
# - Generates AI commit message
# - Pushes to remote
# - Creates/updates PR
# - Shows summary report
```

### Monorepo Management

```bash
# Work on multiple packages/services
D push --recursive
# Runs _commit-push-pr on all selected submodules

D pull --recursive
# Pulls and merges latest changes in all submodules
```

### Emergency Fixes

```bash
# Direct commit to main (with safety confirmation)
git checkout main
D push
# Prompts: Type 'PUSH TO MAIN' to confirm

# Quick hotfix PR
D git pre           # Create PR without new commits
```

## PR Status Insights

### Review States

- **APPROVED** ✅ - Ready to merge
- **CHANGES_REQUESTED** ❌ - Action required
- **REVIEW_REQUIRED** ⏳ - Awaiting review
- **No reviews yet** 📝 - Just created

### Comment Management

- Shows unresolved comment count
- Displays first 5 unresolved comments
- Indicates total pending items

## Advanced Configuration

### GitHub CLI Setup

```bash
# Install and authenticate GitHub CLI
gh auth login

# Verify authentication
gh auth status
```

### AI Commit Messages

```bash
# Add OpenAI API key for intelligent commits
D secret add
# Enter: OPENAI_API_KEY
# Value: sk-your-openai-key

# Test AI functionality
D push  # Will use AI for commit message generation
```

### Branch Naming

The kit auto-detects your username from git email format:

- Email: `user+username@domain.com` → Branch: `username`
- Manual override available during `D git che`

## Integration Notes

### Container Environment

Git commands automatically run in kit container when available:

- Ensures consistent environment
- Access to all dependencies
- Proper secret management

### Internet Connectivity

- Commands gracefully handle offline scenarios
- PR status checks skipped when disconnected
- Local git operations continue working

### Fallback Modes

- **No GitHub CLI**: Creates PR links for manual creation
- **No OpenAI API**: Uses intelligent file-based commit messages
- **No Internet**: Local git operations only

## Troubleshooting

### Common Issues

**"Nothing to commit or push"**

- Repository is already up to date
- Check `git status` for pending changes

**"GitHub CLI not authenticated"**

```bash
gh auth login
```

**"Detached HEAD state"**

- Kit automatically prompts for branch creation
- Safe operation with change preservation

**"Changes requested on PR"**

- Check `D git _status` for specific feedback
- Address comments before new commits

### Debug Commands

```bash
# Check current git state
git status
git log --oneline -5

# Verify GitHub CLI
gh auth status
gh pr list

# Check kit environment
D status
```

## Best Practices

1. **Regular Status Checks**: Run `D git _status` before major changes
2. **Descriptive Branches**: Use meaningful branch names beyond username
3. **Review Before Push**: Check diff with `git diff` before `D push`
4. **Address Comments**: Use `D git _status` to track PR feedback
5. **Keep Branches Fresh**: Regular `D pull` to stay current with main

---

**Part of DISEEC DevOps Kit** • [Full Documentation](../README.md)
