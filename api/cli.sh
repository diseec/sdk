#!/bin/bash

source_once "$D_SDK_DIR/api/index.sh"

D_LOG_LEVEL="DEBUG"
D_DEBUG="true"

c=$1; shift; case $c in
    v1) sdk_api_v1 "$@" ;;
    *) display_help "" "" \
        "$(ansi 97 'API Commands')" "" \
        "    v1          " "API, version 1 interface style"
    ;;
esac