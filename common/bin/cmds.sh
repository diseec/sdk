#!/bin/sh

cmd_version() {
    message 40 "v$VERSION" "DISEEC DevOps CLI — Automation Toolkit"
}

cmd_install() {
    set -e; cd $ROOT_DIR;
    cmd_version
    if [ "$HAS_SUBMODULES" = "true" ]; then
        message "Submodules detected. Cloning submodules .."
        git submodule update --init --recursive --remote
    fi
    if [ -z "$CI" ]; then
        GH_USERNAME=$(printf '%s' "$(git config user.email)" | cut -d'+' -f2 | cut -d'@' -f1)
        read -p "$(message 45 "⁇" "Branch to checkout: (press enter for '$GH_USERNAME')")" BRANCH
        if [ -z "$BRANCH" ]; then BRANCH="$GH_USERNAME"; fi
        message "Checking out branch '$BRANCH' in submodules .."
        git fetch && git checkout $BRANCH || git checkout -b $BRANCH origin/$BRANCH || git checkout -b $BRANCH;
        git submodule foreach 'git fetch && git checkout '$BRANCH' || git checkout -b '$BRANCH' origin/'$BRANCH' || git checkout -b '$BRANCH';'
    fi
    if [ "$HAS_SUBMODULES" = "true" ]; then
        git submodule foreach $ROOT_DIR'/$name/cli install'
    fi
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
        message "Updating submodules .."
        # git submodule update --remote --merge
        git submodule foreach $ROOT_DIR'/$name/cli pull'
    fi
}

cmd_dev() {
    set -e
    cmd_version
    $0 status
    ask_to_run_command "Pull latest repo changes from all repos?" $0 pull
    ask_to_run_command "Build fresh images?" $0 build
    if [ "$IS_IN_CONTAINER" = "true" ]; then
        eval $(grep -m 1 'command:' "$ROOT_DIR/docker-compose.override.yaml" | sed 's/.*command: //')
    else
        docker compose up
        docker compose down
    fi
    echo "\n"
    message 45 "k1" "DO NOT FORGET TO make PR. 🚀"
    echo "\n"
}

cmd_pro() {
    set -e
    cmd_version
    message "Starting services in production mode .."
    docker compose -f "$ROOT_DIR/docker-compose.yaml" up "$@"
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
        $0 exec "$REPO_NAME" "$@"
    else
        message "45" "SERVICES:" "\n$services"
        read -p "$(message 45 "⁇" "Specify a service to run:")" service
        $0 exec "$service" "$@"
    fi
}

cmd_exec() {
    service=$1; shift
    execute_command_in_container "$service" "$@"
}

cmd_shell() {
    cmd_version
    $0 run /bin/sh
}

cmd_test() {
    . ./bin/test.sh "$@"
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
    . ./bin/services.sh "$@"
}

cmd_package() {
    . ./bin/packages.sh "$@"
}

cmd_help() {
    display_help \
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
        "    kit          "  "Run a command in SDK image, usage: kit <command>" \
        "    service      "  "Run a command in a service, usage: service <command>" \
        "    package      "  "Run a command in a package, usage: package <command>" \
        "    version      "  "Show the current kit version" \
        "$@"
    exit 1
}

cmd_unknown() {
    message 41 "error" "Unknown command: $command"
    "$ROOT_DIR/cli" help
}