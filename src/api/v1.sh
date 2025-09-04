#!/bin/bash

src_api_v1(){
    local c=$1; shift; case $c in
        install) cli_main install ;;
        install.--recursive) cli_main install --recursive ;;
        update.--recursive) cli_main update --recursive ;;
        git.commit.push.pr.--recursive) cli_main git commit-push-pr --recursive ;;
        git.log.--today) cli_main git log --today ;;
        pull.--recursive) cli_main git pull --recursive ;;
        *) display_help "" "" \
            "$(ansi 97 'API v1 Commands')" "" \
            "    install     " "Install API v1 dependencies"
        ;;
    esac
}
