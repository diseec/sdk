#!/bin/bash

export ORG_NAME="diseec"
export KIT_NAME="kit"
export PROJECT_MOUNT_DIR="/vise"
export IMAGE_REGISTRY_URL="image.registry.$ORG_NAME.com"
export KIT_IMAGE="$IMAGE_REGISTRY_URL/$KIT_NAME"
export REPO_HUB_URL="github.com/$ORG_NAME"
export KIT_RELATIVE_PATH="node_modules/@diseec/$KIT_NAME"

if [ ! -n "$KIT_DIR" ]; then
    export KIT_DIR="$(_npm config get prefix)/lib/$KIT_RELATIVE_PATH"
fi

auto_discover_project_root_dir() {
    # Canonicalize KIT_DIR
    KIT_DIR=$(cd "$KIT_DIR" 2>/dev/null && pwd -P) || {
        message 41 "Error: can't access '$KIT_DIR'" >&2
        exit 1
    }
    # Exception: if the script's directory == KIT_DIR, return the first cli
    # script_dir=$(cd "$(dirname -- "$0")" 2>/dev/null && pwd -P || echo "")
    # if [ -n "$script_dir" ] && [ "$script_dir" = "$KIT_DIR" ] && [ -f "$KIT_DIR/cli" ]; then
    if [ "$IS_KIT_CLI" = "true" ]; then
        printf '%s\n' "$KIT_DIR"
        return 0
    fi
    # Start from the parent of KIT_DIR, as an absolute, canonical path
    start=$(cd "$KIT_DIR/.." 2>/dev/null && pwd -P) || {
        message 41 error "can't access '$KIT_DIR/..'" >&2
        exit 1
    }
    dir=$start
    while :; do
        if [ -f "$dir/cli" ]; then
            # Skip if it's the same file as $KIT_DIR/cli
            if [ ! -e "$KIT_DIR/cli" ] || [ ! "$dir/cli" -ef "$KIT_DIR/cli" ]; then
                printf '%s\n' "$dir"
                return 0
            fi
        fi
        [ "$dir" = "/" ] && break
        dir=$(dirname -- "$dir")
    done
    message 41 error "Could not find an ancestor containing a 'cli' other than '$KIT_DIR/cli'" >&2
    exit 1
}
if [ ! -n "$ROOT_DIR" ]; then
# if [ ! -f "$ROOT_DIR/cli" ]; then
    export ROOT_DIR="$(auto_discover_project_root_dir)"
fi

if [ "$IS_IN_KIT_CONTAINER" = "true" ]; then 
    export ROOT_DIR="$PROJECT_MOUNT_DIR";
    if [ -d "$ROOT_DIR/$KIT_RELATIVE_PATH" ]; then
        export KIT_DIR="$ROOT_DIR/$KIT_RELATIVE_PATH";
    else
        export KIT_DIR="/$KIT_NAME";
    fi
fi
export KIT_SRC_DIR="$KIT_DIR/src"
export CLI="$ROOT_DIR/cli"
export CLI_BASE="$KIT_SRC_DIR/cli.sh"

export VERSION=$(grep '"version"' $KIT_DIR/package.json | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')

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

get_org_dir() {
  ORG_DIR="$HOME/$ORG_NAME"
  if [ ! -d "$ORG_DIR" ]; then mkdir -p "$ORG_DIR"; fi
  echo "$ORG_DIR"
}
export ORG_DIR=$(get_org_dir)

get_cache_dir() {
  ORG_CACHE_DIR="$ORG_DIR/.cache"
  if [ ! -d "$ORG_CACHE_DIR" ]; then mkdir -p "$ORG_CACHE_DIR"; fi
  echo "$ORG_CACHE_DIR"
}
export ORG_CACHE_DIR=$(get_cache_dir)

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
