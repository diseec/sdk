#!/bin/sh

cmd_version() {
    message 40 "v$VERSION" "DISEEC DevOps CLI — Automation Toolkit"
}

cmd_install_cli_globally() {
    npm install -g "$(grep '"name"' $CLI_ROOT/package.json | head -n1 | sed 's/.*: *"\([^"]*\)".*/\1/')@latest"
}

cmd_install() {
    set -e; cd $ROOT_DIR; cmd_version;
    
    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { message 33 "CI" "Skipping interactive installation in CI environment"; return 0; }
    # Early return if no submodules
    [ "$HAS_SUBMODULES" != "true" ] && { return 0; }
    
    
    # Load workspace functions to get the config path
    . $CLI_SRC/workspace.sh
    
    if [ ! -f "$(get_workspace_config_path)" ]; then
        message 34 "WORKSPACE" "Initializing workspace configuration..."
        cmd_workspace_init
    fi
    selected_modules=$(get_selected_modules)

    message "Cloning selected submodules..."
    initialize_submodule() {
        local module="$1"; local module_path="$2"
        message 34 "$module" "Initializing submodule..."
        git submodule update --init --recursive --remote "$module_path"
    }
    foreach_selected_module_with_callback initialize_submodule

    message "Setting up branch tracking..."
    GH_USERNAME=$(printf '%s' "$(git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
    read -p "$(message 45 "⁇" "Branch to checkout: (press enter for '$GH_USERNAME')")" BRANCH
    if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi
    message "Checking out branch '$BRANCH' in super repo..."
    git fetch && git checkout $BRANCH || git checkout -b $BRANCH origin/$BRANCH || git checkout -b $BRANCH;
    message "Checking out branch '$BRANCH' in selected submodules..."
    checkout_branch() {
        local module="$1"; local module_path="$2"; local branch="$3"
        message 34 "$module" "Checking out branch..."
        (cd "$ROOT_DIR/$module_path" && git fetch && git checkout $branch || git checkout -b $branch origin/$branch || git checkout -b $branch)
    }
    foreach_selected_module_with_callback checkout_branch "$BRANCH"
    
    message "Installing dependencies in selected submodules..."
    install_dependencies() {
        local module="$1"
        local module_path="$2"
        message 34 "$module" "Installing dependencies..."
        (cd "$ROOT_DIR/$module_path" && $ROOT_DIR/$module_path/cli install)
    }
    foreach_selected_module_with_callback install_dependencies
    message 32 "success" "Workspace configuration initialized successfully."
}

cmd_status() {
    informer summary-branch-status
    informer forbid-dev-on-main
}

cmd_pull() {
    cd $ROOT_DIR;
    message 34 "$(git branch --show-current)" "Pulling latest changes .."
    git pull origin
    message 34 "$(git branch --show-current)" "Merging latest 'main' changes .."
    git merge origin/main
    
    if [ "$HAS_SUBMODULES" = "true" ]; then
        message "Updating workspace submodules .."
        
        selected_modules=$(get_selected_modules)
        pull_submodule() {
            local module="$1"
            local module_path="$2"
            (cd "$ROOT_DIR/$module_path" && $ROOT_DIR/$module_path/cli pull)
        }
        foreach_selected_module_with_callback pull_submodule
    fi
}

cmd_dev() {
    set -e
    cmd_version
    "$ROOT_DIR/cli" status
    
    # Filter services based on workspace configuration
    services_filter=$(get_services_filter)
    
    if [ "$IS_IN_CONTAINER" = "true" ]; then
        eval $(grep -m 1 'command:' "$ROOT_DIR/docker-compose.override.yaml" | sed 's/.*command: //')
    else
        # Set up a trap to ensure we stop all containers on exit or interrupt
        cleanup() {
            message 43 "CLEANUP" "Stopping all containers..."
            docker compose down
            exit 0
        }
        # Trap SIGINT (Ctrl+C) and EXIT
        trap cleanup INT EXIT
        
        if [ -n "$services_filter" ]; then
            message 34 "WORKSPACE" "Starting selected services: $services_filter"
            docker compose up $services_filter
        else
            docker compose up
        fi
    fi
}

cmd_pro() {
    set -e
    cmd_version
    message "Starting services in production mode .."

    # Filter services based on workspace configuration
    services_filter=$(get_services_filter)
    
    # Set up a trap to ensure we stop all containers on exit or interrupt
    cleanup() {
        message 43 "CLEANUP" "Stopping all containers..."
        docker compose -f "$ROOT_DIR/docker-compose.yaml" down
        exit 0
    }
    # Trap SIGINT (Ctrl+C) and EXIT
    trap cleanup INT EXIT
    
    if [ -n "$services_filter" ]; then
        message 34 "WORKSPACE" "Starting selected services in production mode: $services_filter"
        docker compose -f "$ROOT_DIR/docker-compose.yaml" up $services_filter "$@"
    else
        docker compose -f "$ROOT_DIR/docker-compose.yaml" up "$@"
    fi
}

cmd_build() {
    set -e
    cmd_version
    message "Building service images .."
    docker compose build --parallel
}

cmd_run() {
    services=$(docker compose config --services)
    if echo "$services" | grep -qx "$REPO_NAME"; then
        "$ROOT_DIR/cli" exec "$REPO_NAME" "$@"
    else
        message "45" "SERVICES:" "\n$services"
        read -p "$(message 45 "⁇" "Specify a service to run:")" service
        "$ROOT_DIR/cli" exec "$service" "$@"
    fi
}

cmd_exec() {
    service=$1; shift
    execute_command_in_container "$service" "$@"
}

cmd_shell() {
    cmd_version
    "$ROOT_DIR/cli" run /bin/sh
}

cmd_test() {
    . $CLI_SRC/test.sh "$@"
}

cmd_release() {
    TAG="v$(date +%Y%m%d%H%M%S)"
    git checkout main
    git pull origin main
    git tag -a $TAG -m "Release $TAG"
    git push origin $TAG
}

cmd_kit() {
    docker run --rm -it \
        -w /app \
        -v "$(pwd)":/app \
        --pull always \
        $IMAGE_REGISTRY_URL/kit kit "$@"
}

cmd_service() {
    . $CLI_SRC/services.sh "$@"
}

cmd_package() {
    . $CLI_SRC/packages.sh "$@"
}

cmd_format() {
    set -e; cd $ROOT_DIR;
    if ! grep -q '"prettier"' "$ROOT_DIR/package.json"; then
        message 43 "!" "Prettier not found. Installing..."
        install_prettier
    fi
    message 34 "Prettier" "Running formatter..."
    run_prettier() {
        docker run --rm \
            -v $(pwd):/project \
            --workdir "/project" \
            $IMAGE_REGISTRY_URL/devops \
            yarn prettier "$@";
    }
    if [ "$CI" = "true" ]; then 
        run_prettier --check --log-level=warn "$@";
    else
        run_prettier --write --log-level=warn "$@";
    fi
}

cmd_help() {
    # TODO individual comamnds must be able to register their own help to here
    display_help \
        "" "" \
        "$(color 33 'Usage:')" "" \
        "$(color 32 '    command [options] [arguments]\n')" "" \
        "$(color 33 'Base Commands:')" "" \
        "    install      "  "Install the dependencies" \
        "    status       "  "Show project status" \
        "    pull         "  "Pull the repo and image from registry" \
        "    dev          "  "Start the development server" \
        "    pro          "  "Start the production server" \
        "    build        "  "Build the image push to registry" \
        "    run          "  "Run a command in fresh instance, usage: run <command>" \
        "    exec         "  "Run a command in a service container, usage: exec <service-name> <command>" \
        "    shell        "  "Start a shell" \
        "    test         "  "Run the tests in production mode, see: test -h" \
        "    release      "  "Merge to release branch to trigger CD pipeline" \
        "    format       "  "Check if Prettier exists and run formatting on codebase" \
        "    kit          "  "Run a command in SDK image, usage: kit <command>" \
        "    service      "  "Run a command in a service, usage: service <command>" \
        "    package      "  "Run a command in a package, usage: package <command>" \
        "    envs         "  "All exported envs, source project cli to load them!" \
        "    version      "  "Show the current kit version" \
        "$(color 33 '\nWorkspace Commands:')" "" \
        "    workspace           "  "Manage workspace configuration" \
        "    workspace init      "  "Initialize workspace configuration" \
        "    workspace select    "  "Select modules for workspace" \
        "    workspace status    "  "Show current workspace configuration" \
        "$@"
}

cmd_workspace() {
    subcommand=$1
    case "$subcommand" in
        init) cmd_workspace_init ;;
        select) cmd_workspace_select ;;
        status) cmd_workspace_status ;;
        *)
            message 33 "WORKSPACE" "Available workspace commands:"
            echo "  init    - Initialize workspace configuration"
            echo "  select  - Select modules for workspace"
            echo "  status  - Show current workspace configuration"
            ;;
    esac
}

cmd_unknown() {
    # # ── make $command safe for a POSIX Extended Regular Expression ────────────────
    # command_re=$(printf '%s\n' "$command" | sed 's/[][\/.^$*+?{}|()\\-]/\\&/g')

    # # ── look the token up in $ROOT_DIR/cli ────────────────────────────────────────
    # # -E              → use POSIX *Extended* REs (gives us + and | without back-slashes)
    # # -q              → quiet; we only need the exit status
    # # /dev/null redir → silence any accidental stdout on weird greps
    # if ! grep -Eq '^[[:blank:]]*([A-Za-z0-9-]+\|)*'"$command_re"'(\|[A-Za-z0-9-]+)*\)$' \
    #         "$ROOT_DIR/cli" >/dev/null
    # then
    
    if [ ! -z "$command" ]; then
        message 41 "error" "Unknown command: '$command'"
    fi
    "$ROOT_DIR/cli" help
    exit 1
    # fi
}