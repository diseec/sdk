#!/bin/bash

D_GLOB_LOG_LEVEL="DEBUG"

WATCH_DIR="$D_SDK_DIR"
TARGET_PATHS=(
    "$D_SDK_DIR/../../node_modules/@diseec/sdk"
    "$D_SDK_DIR/../../services/d0-cms/node_modules/@diseec/sdk"
    "$D_SDK_DIR/../../services/d0-www/node_modules/@diseec/sdk"
)
 
get_checksum() {
    find "$WATCH_DIR" -type f -exec md5sum {} \; | sort | md5sum
}

last_checksum=$(get_checksum)
trap "stdout -w 'Sync server stopped.'; exit" SIGINT

stdout -s "Started development server"
stdout -s "Watching for changes in '$WATCH_DIR'"

while true; do
    sleep 1
    new_checksum=$(get_checksum)

    if [ "$new_checksum" != "$last_checksum" ]; then
        stdout -i --processing "Changes detected, syncing"
        for TARGET in "${TARGET_PATHS[@]}"; do
            mkdir -p "$TARGET"
            cp -r "$WATCH_DIR/." "$TARGET/"
        done
        stdout -i --icon="⇆" --ansi="32" "Synced to all targets"
        last_checksum=$new_checksum
    fi
done
