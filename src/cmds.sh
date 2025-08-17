#!/bin/sh

cmd_version() {
    message 40 "v$VERSION" "DISEEC DevOps CLI — Automation Toolkit"
}

cmd_install() {
    set -e; cd $ROOT_DIR; cmd_version;

    ARGS=""; for arg in "$@"; do case "$arg" in
        --ignore-submodule-installation) IGNORE_SUBMODULE_INSTALLATION="true";;
    *) ARGS="$ARGS \"$arg\"";; esac; done; eval set -- $(eval echo $ARGS);

    git config --global credential.helper store

    # Early return in CI environment - silent skip
    [ -n "$CI" ] && { message 33 "CI" "Skipping interactive installation in CI environment"; return 0; }
    # Early return if no submodules
    [ "$HAS_SUBMODULES" != "true" ] && { return 0; }
    
    if [ ! -f "$(get_workspace_config_path)" ]; then
        message 30 "WORKSPACE" "Initializing workspace configuration..."
        cmd_workspace_init
    fi

    message "Cloning selected submodules..."
    initialize_submodule() {
        local module="$1"; local module_path="$2"
        message 30 "$module" "Initializing submodule..."
        _git submodule update --init --recursive --remote "$module_path"
    }
    foreach_selected_module_with_callback initialize_submodule

    message "Setting up branch tracking..."
    GH_USERNAME=$(printf '%s' "$(_git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
    read -p "$(message 45 "⁇" "Branch to checkout: (press enter for '$GH_USERNAME')")" BRANCH
    if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi
    message "Checking out to branch '$BRANCH'..."
    _git fetch && _git checkout $BRANCH || _git checkout -b $BRANCH origin/$BRANCH || _git checkout -b $BRANCH;
    # message "Checking out branch '$BRANCH' in selected submodules..."
    # checkout_branch() {
    #     local module="$1"; local module_path="$2"; local branch="$3"
    #     message 30 "$module" "Checking out branch..."
    #     (cd "$ROOT_DIR/$module_path" && _git fetch && _git checkout $branch || _git checkout -b $branch origin/$branch || _git checkout -b $branch)
    # }
    # foreach_selected_module_with_callback checkout_branch "$BRANCH"
    
    if [ "$IGNORE_SUBMODULE_INSTALLATION" != "true" ]; then
        message "Installing dependencies in selected submodules..."
        install_dependencies() {
            local module="$1"
            local module_path="$2"
            message 30 "$module" "Installing dependencies..."
            (cd "$ROOT_DIR/$module_path" && $ROOT_DIR/$module_path/cli install)
        }
        foreach_selected_module_with_callback install_dependencies
    fi

    message 42 "OKEY" "Workspace configuration initialized successfully."
}

cmd_dev() {
    set -e
    
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
            message 30 "WORKSPACE" "Starting selected services: $services_filter"
            docker compose up $services_filter
        else
            docker compose up
        fi
    fi
}

cmd_pro() {
    set -e

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
        message 30 "WORKSPACE" "Starting selected services in production mode: $services_filter"
        docker compose -f "$ROOT_DIR/docker-compose.yaml" up $services_filter "$@"
    else
        docker compose -f "$ROOT_DIR/docker-compose.yaml" up "$@"
    fi
}

cmd_build() {
    set -e
    message "Building service images .."
    docker compose build --parallel
}

cmd_exec() {
    service=$1; shift
    execute_command_in_container "$service" "$@"
}

cmd_shell() {
    $CLI run /bin/sh
}

cmd_test() {
    . $KIT_SRC_DIR/test.sh "$@"
}

cmd_kit() {
    docker run --rm -it \
        -w /app \
        -v "$(pwd)":/app \
        --pull always \
        $IMAGE_REGISTRY_URL/kit kit "$@"
}

cmd_service() {
    . $KIT_SRC_DIR/services.sh "$@"
}

cmd_package() {
    . $KIT_SRC_DIR/packages.sh "$@"
}

cmd_event() {
    . $KIT_SRC_DIR/events.sh "$@"
}

cmd_format() {
    set -e; cd $ROOT_DIR;
    if ! grep -q '"prettier"' "$ROOT_DIR/package.json"; then
        message 43 "!" "Prettier not found. Installing..."
        install_prettier
    fi
    message 30 "Prettier" "Running formatter..."
    if [ "$CI" = "true" ]; then 
        $CLI run yarn prettier --check --log-level=warn "$@";
    else
        $CLI run yarn prettier --write --log-level=warn "$@";
    fi
}

cmd_help() {
    # TODO individual comamnds must be able to register their own help to here
    display_help \
        "" "" \
        "$(color 33 'Usage:')" "" \
        "$(color 32 '    command [options] [arguments]\n')" "" \
        "$(color 33 'Base Commands:')" "" \
        "    ins|install      "  "Install the dependencies" \
        "    upd|update       "  "Sync project with latest updates" \
        "    sta|status       "  "Show project status" \
        "    pul|pull         "  "Pull and merge latest changes from repository. Alias to 'cli git pull'" \
        "    pus|push         "  "Automated commit->push->pr process with AI generated message. Alias to 'cli git push'" \
        "    dev              "  "Start the development server" \
        "    pro              "  "Start the production server" \
        "    bui|build        "  "Build the image push to registry" \
        "    run              "  "Run a command in fresh instance, usage: run <command>" \
        "    exe|exec         "  "Run a command in a service container, usage: exec <service-name> <command>" \
        "    she|shell        "  "Start a shell" \
        "    tes|test         "  "Run the tests in production mode, see: test -h" \
        "    rel|release      "  "Merge to release branch to trigger CD pipeline" \
        "    for|format       "  "Check if Prettier exists and run formatting on codebase" \
        "    git              "  "Git management commands run: cli git help" \
        "    $KIT_NAME           "  "Run a command in SDK image, usage: $KIT_NAME <command>" \
        "    ser|service      "  "Run a command in a service, usage: cli service <command>" \
        "    pac|package      "  "Run a command in a package, usage: cli package <command>" \
        "    wor|workspace    "  "Manage workspace configuration [init|select|status]" \
        "    env|envs         "  "All exported envs, source project cli to load them!" \
        "    ver|version      "  "Show the current kit version" \
        "$@"
}

cmd_unknown() {
    # # ── make $command safe for a POSIX Extended Regular Expression ────────────────
    # command_re=$(printf '%s\n' "$command" | sed 's/[][\/.^$*+?{}|()\\-]/\\&/g')

    # # ── look the token up in $CLI ────────────────────────────────────────
    # # -E              → use POSIX *Extended* REs (gives us + and | without back-slashes)
    # # -q              → quiet; we only need the exit status
    # # /dev/null redir → silence any accidental stdout on weird greps
    # if ! grep -Eq '^[[:blank:]]*([A-Za-z0-9-]+\|)*'"$command_re"'(\|[A-Za-z0-9-]+)*\)$' \
    #         $CLI >/dev/null
    # then
    
    if [ ! -z "$command" ]; then
        message 41 "error" "Unknown command: '$command'"
    fi
    $CLI help
    exit 1
    # fi
}