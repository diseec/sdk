#!/bin/bash

source_once "$D_SDK_DIR/facades/docker/index.sh"

# cli_ctx envs > /dev/null # export envs so docker compose can pick them

c=$1; shift; case $c in
    com|compose) c=$1; shift; case $c in
        ude|up-dev|up) sdk_fac_doc_up_development "$@" ;;
        upr|up-pro) sdk_fac_doc_up_production "$@" ;;
        exe|execute|exec) sdk_fac_doc_cmd_docker_execute "$@" ;;
        bui|build) cli_ctx docker compose _ build --parallel "$@" ;;
        _) sdk_fac_doc_compose "$@" ;;
        hel|help|--help|-h) display_help "" "" \
            "$(ansi 97 'Docker Compose Commands')" "" \
            "    ude|up|up-dev   " "Start development environment" \
            "    upr|up-pro      " "Start production environment" \
            "    exe|exec        " "Execute command in compose service" \
            "    bui|build       " "Build all services in parallel" \
            "    _               " "Direct docker compose command passthrough"
        ;;
        *)
            if [[ -n "$c" ]]; then stdout -e "Unknown command: '$c'"; fi
            cli_ctx docker compose help; return 1;
        ;;
    esac ;;
    _) _docker "$@" ;;
    hel|help|--help|-h) display_help "" "" \
        "$(ansi 97 'Docker Commands')" "" \
        "    com|compose         " "Docker compose operations" \
        "    _                   " "Direct docker command passthrough"
    ;;
    fun|function) "$@" ;;
    *)
        if [[ -n "$c" ]]; then stdout -e "Unknown command: '$c'"; fi
        cli_ctx docker help; return 1;
    ;;
esac
