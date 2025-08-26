#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

main() {
    export  IMAGE_REGISTRY_URL \
            REPO_NAME \
            ROOT_DIR \
            ORG_CACHE_DIR \
            KIT_NAME \
            KIT_DIR \
            PROJECT_MOUNT_DIR_NAME

    SRC "facades/docker/up-development.sh"
    SRC "facades/docker/up-production.sh"
    SRC "facades/docker/execute.sh"

    c=$1; shift; case "$c" in
        com|compose) c=$1; shift; case "$c" in
            ude|_up|_up-dev) up_development "$@" ;;
            upr|_up-pro) up_production "$@" ;;
            exe|_exec) cmd_docker_execute "$@" ;;
            bpa|_build) _docker compose build --parallel "$@" ;;
            hel|help|--help|-h) display_help "" "" \
                "$(color 30 'Docker Compose Commands')" "" \
                "    ude|_up|_up-dev  " "Start development environment" \
                "    upr|_up-pro      " "Start production environment" \
                "    exe|_exec        " "Execute command in compose service" \
                "    bpa|_build       " "Build all services in parallel" \
                "    <docker-compose-cmd>" "Pass through to docker compose"
            ;;
            *) _docker compose "$c" "$@" ;;
        esac ;;
        hel|help|--help|-h) display_help "" "" \
            "$(color 30 'Docker Commands')" "" \
            "    com|compose         " "Docker compose operations" \
            "    <docker-cmd>        " "Pass through to docker"
        ;;
        *) _docker "$c" "$@" ;;
    esac
}

main "$@"

