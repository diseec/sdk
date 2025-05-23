#!/bin/sh

. "./bin/helpers.sh";

cmd_install_nodejs() {
    set -e
    if [ -n "$SERVICE_NAME" ]; then
        sh cli run yarn install
        # if [ -z "$CI" ]; then
        #     ask_to_run_command "Install test utils?" sh cli run yarn playwright install
        # else
        #     sh cli run yarn playwright install
        # fi
    fi
    if [ "$IS_MONOREPO" = "true" ]; then
        if git submodule status 2>/dev/null | grep -qv '^ '; then
            message "Submodules are already initialized. Exiting .."
            exit 0
        fi
        message "Submodules detected. Cloning submodules .."
        git submodule update --init --recursive
        git submodule foreach 'sh cli install'
    fi
}

cmd_status() {
    informer summary-branch-status
    informer forbid-dev-on-main
}

cmd_pull() {
    message 34 "$(git branch --show-current)" "Pulling latest changes .."
    git pull origin
    message 34 "$(git branch --show-current)" "Merging latest 'main' changes .."
    git merge origin/main
    # message "Pulling the image .."
    # docker pull $IMAGE_REGISTRY_URL/$REPO_NAME
    if [ "$IS_MONOREPO" = "true" ]; then
        message "Updating submodules .."
        # git submodule update --remote --merge
        git submodule foreach 'sh cli pull'
    fi
}

cmd_dev() {
    set -e
    sh cli status
    ask_to_run_command "Pull latest repo changes from all repos?" sh cli pull
    ask_to_run_command "Build fresh images?" sh cli build
    if [ "$IS_IN_CONTAINER" = "true" ]; then
        eval $(grep -m 1 'command:' docker-compose.override.yaml | sed 's/.*command: //')
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
    message "Starting services in production mode .."
    docker compose -f docker-compose.yaml up "$@"
}

cmd_build() {
    set -e
    message "Building service images .."
    docker compose build --parallel
}

cmd_run() {
    if [ "$IS_MONOREPO" = "true" ]; then
        if [ -n "$SERVICE_NAME" ]; then
            sh cli exec $SERVICE_NAME "$@"
        else
            read -p "$(message 45 "⁇" "Specify a service to run:")" service
            sh cli exec "$service" "$@"
        fi
    else
        sh cli exec $SERVICE_NAME "$@"
    fi
}

cmd_exec() {
    service=$1; shift
    execute_command_in_container "$service" "$@"
}

cmd_shell() {
    sh cli run /bin/sh
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

cmd_submodule() {
    . ./bin/submodule.sh "$@"
}

cmd_help() {
    printf "\n"
    display_help \
        "install  "  "Install the dependencies" \
        "status   "  "Show project status" \
        "pull     "  "Pull the repo and image from registry" \
        "dev      "  "Start the development server" \
        "pro      "  "Start the production server" \
        "build    "  "Build the image push to registry" \
        "run      "  "Run a command in fresh instance, usage: run <command>" \
        "exec     "  "Run a command in a service container, usage: exec <service-name> <command>" \
        "shell    "  "Start a shell" \
        "test     "  "Run the tests in production mode, see: test -h" \
        "release  "  "Merge to release branch to trigger CD pipeline" \
        "kit      "  "Run a command in SDK image, usage: kit <command>" \
        "submodule"  "Run a command in a submodule, usage: submodule <command>"
    exit 0
}

cmd_unknown() {
    message 41 "error" "Unknown command: $command"
    sh cli help
}