#!/bin/bash

sdk_api_v1(){
    local c=$1; shift; case $c in
        install) cli_ctx install ;;
        install) cli_ctx install ;;
        update) cli_ctx update ;;
        git.commit.push.pr) cli_ctx git commit-push-pr ;;
        git.log.--today) cli_ctx git log --today ;;
        pull) cli_ctx git pull ;;
        *) display_help "" "" \
            "$(ansi 97 'API v1 Commands')" "" \
            "    install     " "Install API v1 dependencies"
        ;;
    esac
}
