#!/bin/bash

sdk_api_v1(){
    local c=$1; shift; case $c in
        install) cli_ctx install ;;
        install.--recursive) cli_ctx install --recursive ;;
        update.--recursive) cli_ctx update --recursive ;;
        git.commit.push.pr.--recursive) cli_ctx git commit-push-pr --recursive ;;
        git.log.--today) cli_ctx git log --today ;;
        pull.--recursive) cli_ctx git pull --recursive ;;
        *) display_help "" "" \
            "$(ansi 97 'API v1 Commands')" "" \
            "    install     " "Install API v1 dependencies"
        ;;
    esac
}
