#!/bin/bash

# Git automation utilities for PR workflows
# This script provides functions for:
# 1. Automatically creating PRs with AI-generated commit messages
# 2. Checking existing PRs for unresolved issues/comments

# cli_main envs > /dev/null # export envs so docker compose can pick them

c=$1; shift; case $c in
    com|compose) c=$1; shift; case $c in
        ude|up-dev|up) fac_doc_up_development "$@" ;;
        upr|up-pro) fac_doc_up_production "$@" ;;
        exe|execute|exec) fac_doc_cmd_docker_execute "$@" ;;
        bpa|build) _docker compose build --parallel "$@" ;;
        _) _docker compose "$@" ;;
        hel|help|--help|-h) display_help "" "" \
            "$(ansi 97 'Docker Compose Commands')" "" \
            "    ude|up|up-dev   " "Start development environment" \
            "    upr|up-pro      " "Start production environment" \
            "    exe|exec        " "Execute command in compose service" \
            "    bpa|build       " "Build all services in parallel" \
            "    _               " "Direct docker compose command passthrough"
        ;;
        *)
            logit -e "Unknown command: '$c'"
            cli_main docker compose help; exit 1;
        ;;
    esac ;;
    _) _docker "$@" ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi 97 'Docker Commands')" "" \
        "    com|compose         " "Docker compose operations" \
        "    _                   " "Direct docker command passthrough"
    ;;
    *)
        logit -e "Unknown command: '$c'"
        cli_main docker help; exit 1;
    ;;
esac
