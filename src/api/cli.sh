#!/bin/bash

source_once "$SDK_SRC_DIR/api/index.sh"

c=$1; shift; case $c in
    v1) src_api_v1 "$@" ;;
    *) display_help "" "" \
        "$(ansi 97 'API Commands')" "" \
        "    v1          " "API version 1 operations"
    ;;
esac