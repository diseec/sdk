#!/bin/bash

source $(dirname "$0")/../helpers.sh
source $(get_root)/bin/installers.sh

load_env

set -e

# Handle pre-installation options
for arg in "$@"; do
    case $arg in
        --fix-all)
            shift
            bash $0 --fix-common --fix-node --fix-php --fix-mysql
            ;;
        --fix-common)
            shift
            install_common_services
            ;;
        --fix-node)
            shift
            if ! [ -x "$(command -v node)" ]; then
                install_node
            fi
            if ! [ -x "$(command -v yarn)" ]; then
                install_yarn
            fi
            ;;
        --fix-php)
            shift
            if ! [ -x "$(command -v php)" ]; then
                install_php
            fi
            if ! [ -x "$(command -v composer)" ]; then
                install_composer
            fi
            ;;
        --fix-mysql)
            shift
            if ! [ -x "$(command -v mysql)" ]; then
                install_mysql
            fi
            ;;
        --help|-h)
            color_output 33 "Options:"
            color_output 0 "    \e[32m--only\e[0m            Install only the specified services (web, api, bld, db, node-base)"
            color_output 0 "    \e[32m--fix-all\e[0m         Install all missing services"
            color_output 0 "    \e[32m--fix-common\e[0m      Install common services"
            color_output 0 "    \e[32m--fix-node\e[0m        Install node and yarn"
            color_output 0 "    \e[32m--fix-php\e[0m         Install php and composer"
            color_output 0 "    \e[32m--fix-mysql\e[0m       Install mysql"
            ;;
    esac
done

# If developing dockerless and requirements doesnt met error
if [ "$DEV_DOCKERLESS" == "0" ]; then
    if ! [ -x "$(command -v node)" ] || ! [ -x "$(command -v yarn)" ] || ! [ -x "$(command -v php)" ] || ! [ -x "$(command -v composer)" ] || ! [ -x "$(command -v mysql)" ]; then
        message error "Requirements not met, run the command with following option:"
        color_output 0 "    \e[32m$0 --fix-all\e[0m"
        exit 1
    fi
fi

# Handle installation
if [ $# -eq 0 ]; then
    # Install all services by default
    bash $0 --only node-base api db
else    
    case $1 in
        --only)
            shift
            case $1 in
                node-base)
                    shift
                    install_node_modules
                    ;;
                web) # node-base included
                    shift
                    cli web install
                    ;;
                api)
                    shift
                    cli api install
                    ;;
                bld) # node-base included
                    shift
                    cli bld install
                    ;;
                db)
                    shift
                    cli db install
                    ;;
                *)
                    bash $0 --help
                    printf "\n"
                    message error "Invalid option: $1"
                    exit 1
                    ;;
            esac
            ;;
    esac
    exit 0
fi