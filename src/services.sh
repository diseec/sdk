#!/bin/sh

cd $ROOT_DIR; command=$1; shift;

case $command in

    add)
        message "Adding service '$1' .."
        set -e;
        git submodule add https://$REPO_HUB_URL/$1.git services/$1
        git submodule update --init --recursive
    ;;

    run)
        services=$(docker compose config --services)
        # if echo "$services" | grep -qx "$REPO_NAME"; then
        #     $CLI exec "$REPO_NAME" "$@"
        # else
        message "45" "SERVICES:" "\n$services"
        read -p "$(message 45 "⁇" "Specify a service to run:")" service
        $CLI exec "$service" "$@"
        # fi
    ;;

    remove|rm)
        ask_to_run_command "Are you sure, remove the service '$1'?" \
            set -e; \
            git submodule deinit -f -- services/$1; \
            rm -rf .git/modules/services/$1; \
            git rm -f services/$1;
    ;;

    update)
        git submodule update --remote --merge
    ;;

    *)
        echo "Usage: $0 service [add|remove|update|run] <service-name>"
        exit 1
    ;;
esac