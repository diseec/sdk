#!/bin/bash

sdk_cmd_opt_version() {
    set +e

    release_date="$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$D_SDK_DIR/package.json")"
    echo "$(ansi 90 "$(capitalize "$D_CLI_GLOBAL_NAME-$D_SDK_NAME") Version") $(ansi 97 "$D_VERSION") $(ansi 90 "$release_date")"

    build_id="$(_docker images --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep "$D_SDK_IMAGE" | head -1 | awk '{print $1}')"
    d_version="$(_npm list -g $D_SDK_NPM_PKG --depth=0 --json 2>/dev/null | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[", ]//g')"
    echo "$(ansi 90 "$D_CLI_GLOBAL_NAME-CLI Version") $(ansi 97 "$d_version") $(ansi 90 "Build") $(ansi 97 "$build_id")"

    echo "$(ansi "2;90" "$D_CLI_GLOBAL_NAME-SRC") $(ansi "2;90" "$D_SDK_DIR")"
    echo "$(ansi "2;90" "$D_CLI_GLOBAL_NAME-CTX") $(ansi "2;90" "$D_CTX_DIR")"
}