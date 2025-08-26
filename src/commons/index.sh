#!/bin/bash

. $KIT_SRC_DIR/commons/output.sh
. $KIT_SRC_DIR/commons/wrappers.sh

on_bench() {
    if [ "$IS_IN_KIT_CONTAINER" != "true" ]; then 
        . $CLI on-bench "$@"
        return 0
    fi
    . "$1"; shift; "$@"; # If we're already in container, source the script and pass remaining arguments
}