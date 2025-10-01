#!/bin/bash

sdk_api_v1(){
    local c=$1; shift; case $c in
        install) cli_ctx --verbose --patch install ;;
        update) cli_ctx --verbose --patch update ;;
        build) cli_ctx --verbose --patch build ;;
        git.commit.push.pr) cli_ctx git commit-push-pr ;;
        git.log.--today) cli_ctx git log --today ;;
        pull) cli_ctx git pull ;;
        *) display_help "" "" \
            "$(ansi 97 'API v1 Commands')" "" \
            "    install     " "Install API v1 dependencies"
        ;;
    esac
}
