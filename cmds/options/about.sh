#!/bin/bash

sdk_cmd_opt_about() {
    printf "\n"
    printf "\e[1;47m    $(capitalize $D_ORG_NAME) DevOps CLI \e[0m\e[1m\e[34m Automation Toolkit \e[0m\e[97mv$D_VERSION\n\e[0m"
    printf "\n"
    printf "\e[90mThis software and associated documentation files\n(the \"Software\") are the  exclusive property  of\n$(capitalize $D_ORG_NAME) L.T.E. and are protected by copyright and\nother intellectual property laws.\nPermission is hereby granted, free of charge, to\nany person obtaining a copy of this Software, to\nse the Software within the organization only.\n\e[0m"
    printf "\n"
    printf "\e[90m\e[1mWebsite  \e[0m\e[90m    https://$D_ORG_NAME.com\n\e[0m"
    printf "\e[90m\e[1mGitHub   \e[0m\e[90m    https://github.com/$D_ORG_NAME\n\e[0m"
    printf "\e[90m\e[1mLinkedIn \e[0m\e[90m    https://linkedin.com/company/$D_ORG_NAME\n\e[0m"
    printf "\n"
    printf "\e[90mCopyright (c) 2018 $(capitalize $D_ORG_NAME),  all rights  reserved\n\e[0m"
    printf "\n"
}
