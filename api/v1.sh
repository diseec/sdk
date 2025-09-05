#!/bin/bash

sdk_api_v1(){
    local c=$1; shift; case $c in
        install) cli_stub install ;;
        install.--recursive) cli_stub install --recursive ;;
        update.--recursive) cli_stub update --recursive ;;
        git.commit.push.pr.--recursive) cli_stub git commit-push-pr --recursive ;;
        git.log.--today) cli_stub git log --today ;;
        pull.--recursive) cli_stub git pull --recursive ;;
        *) display_help "" "" \
            "$(ansi 97 'API v1 Commands')" "" \
            "    install     " "Install API v1 dependencies"
        ;;
    esac
}
