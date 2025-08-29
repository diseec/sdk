#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

c=$1; shift; case "$c" in
    com|compose) c=$1; shift; case "$c" in
        ude|up|up-dev) fac_doc_up_development "$@" ;;
        upr|up-pro) fac_doc_up_production "$@" ;;
        exe|exec) fac_doc_cmd_docker_execute "$@" ;;
        bpa|build) _docker compose build --parallel "$@" ;;
        hel|help|--help|-h) display_help "" "" \
            "$(color 30 'Docker Compose Commands')" "" \
            "    ude|up|up-dev   " "Start development environment" \
            "    upr|up-pro      " "Start production environment" \
            "    exe|exec        " "Execute command in compose service" \
            "    bpa|build       " "Build all services in parallel" \
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
