#!/bin/sh

if [ -z "$CLI_ROOT" ]; then export CLI_ROOT="/bin/@diseec/devops"; fi
export CLI_SRC="$CLI_ROOT/src"
export IMAGE_REGISTRY_URL="image.registry.diseec.com"
export REPOSITORY_URL="github.com/diseec"
export DISEEC_WORKSPACE_DIR="$HOME/diseec"


auto_discover_project_root_dir() {
    # Canonicalize CLI_ROOT
    cli_root=$(cd "$CLI_ROOT" 2>/dev/null && pwd -P) || {
        printf '%s\n' "Error: can't access \$CLI_ROOT" >&2
        return 1
    }
    # Exception: if the script's directory == CLI_ROOT, return the first cli
    script_dir=$(cd "$(dirname -- "$0")" 2>/dev/null && pwd -P || echo "")
    if [ -n "$script_dir" ] && [ "$script_dir" = "$cli_root" ] && [ -f "$cli_root/cli" ]; then
        printf '%s\n' "$cli_root"
        return 0
    fi
    # Start from the parent of CLI_ROOT, as an absolute, canonical path
    start=$(cd "$cli_root/.." 2>/dev/null && pwd -P) || {
        printf '%s\n' "Error: can't access \$CLI_ROOT/.." >&2
        return 1
    }
    dir=$start
    while :; do
        if [ -f "$dir/cli" ]; then
            # Skip if it's the same file as $CLI_ROOT/cli
            if [ ! -e "$cli_root/cli" ] || [ ! "$dir/cli" -ef "$cli_root/cli" ]; then
                printf '%s\n' "$dir"
                return 0
            fi
        fi
        [ "$dir" = "/" ] && break
        dir=$(dirname -- "$dir")
    done
    printf '%s\n' "Error: Could not find an ancestor containing a 'cli' other than \$CLI_ROOT/cli" >&2
    return 1
}
export ROOT_DIR="$(auto_discover_project_root_dir)"

export CLI="$ROOT_DIR/cli"

export VERSION=$(grep '"version"' $CLI_ROOT/package.json | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')

# Extract repository URL from .git/config or submodule gitdir without using git command
GIT_DIR="$ROOT_DIR/.git"
GIT_CONFIG_FILE=""
REPO_URL=""
if [ -d "$GIT_DIR" ]; then
  # Standard git repo
  GIT_CONFIG_FILE="$GIT_DIR/config"
elif [ -f "$GIT_DIR" ]; then
  # Submodule or worktree: .git is a file pointing to actual gitdir
  GITDIR_PATH=$ROOT_DIR/$(awk -F': ' '/^gitdir:/ {print $2}' "$GIT_DIR")
  if [ -n "$GITDIR_PATH" ] && [ -f "$GITDIR_PATH/config" ]; then
    GIT_CONFIG_FILE="$GITDIR_PATH/config"
  fi
fi
if [ -f "$GIT_CONFIG_FILE" ]; then
  REPO_URL=$(awk -F' = ' '/\[remote "origin"\]/ {found=1} found && /url =/ {print $2; exit}' "$GIT_CONFIG_FILE")
fi
# Extract repo name from URL (supports SSH and HTTPS)
REPO_NAME=""
if [ -n "$REPO_URL" ]; then
  # Remove trailing .git if present
  REPO_NAME=$(basename "${REPO_URL%.git}")
fi
export REPO_NAME

get_cache_dir() {
  DISEEC_CACHE_DIR="$DISEEC_WORKSPACE_DIR/.cache"
  if [ ! -d "$DISEEC_CACHE_DIR" ]; then
    mkdir -p "$DISEEC_CACHE_DIR"
  fi
  # Return the cache directory
  echo "$DISEEC_CACHE_DIR"
}
export DISEEC_CACHE_DIR=$(get_cache_dir)

# if [ -n "$NAMESPACE" ] && [ -n "$REPO_NAME" ]; then
#   SERVICE_NAME="${REPO_NAME#$NAMESPACE}"
#   # Remove leading separator if present (e.g., '-' or '/')
#   SERVICE_NAME="${SERVICE_NAME#[-_/.]}"
# else
#   SERVICE_NAME="$REPO_NAME"
# fi
# export SERVICE_NAME

is_in_container() {
    if [ -f "/.dockerenv" ] || [ "$IS_IN_CONTAINER" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}
export IS_IN_CONTAINER=$(is_in_container)

is_monorepo() {
    if [ -d "$ROOT_DIR/services" ] && [ "$(ls -A $ROOT_DIR/services)" ]; then
        echo "true"
    else
        echo "false"
    fi
}
export IS_MONOREPO=$(is_monorepo)

has_submodules() {
    if [ -f "$ROOT_DIR/.gitmodules" ] && [ -s "$ROOT_DIR/.gitmodules" ]; then
        echo "true"
    else
        echo "false"
    fi
}
export HAS_SUBMODULES=$(has_submodules)

# if [ -n "$SERVICE_NAME" ]; then
#     export REPO_NAME="$PROJECT_NAME-$SERVICE_NAME"
# else
#     export REPO_NAME="$PROJECT_NAME"
# fi

# if [ ! -f "$(get_root)/.env" ]; then
#   cp "$(get_root)/.env.example" "$(get_root)/.env"
# fi
# . "$(get_root)/.env"
