#!/bin/bash

sdk_cmd_opt_version() {
    set +e

    # Get package.json modification date in a cross-platform way (works in both macOS and Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        release_date="$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$D_SDK_DIR/package.json" 2>/dev/null)"
    else
        # Linux/Docker
        release_date="$(stat -c "%y" "$D_SDK_DIR/package.json" 2>/dev/null | cut -d. -f1)"
    fi
    echo "$(ansi 90 "$(capitalize "$D_CLI_GLOBAL_NAME-$D_SDK_NAME") Version") $(ansi 97 "$D_VERSION") $(ansi 90 "$release_date")"

    # Check if we're running in Docker or on host
    if command -v docker >/dev/null 2>&1; then
        build_id="$(cli_ctx docker _ images --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep "$D_SDK_IMAGE" | head -1 | awk '{print $1}')"
    else
        build_id="[In Docker - not available]"
    fi
    
    d_version="$(_npm list -g $D_SDK_NPM_PKG --depth=0 --json 2>/dev/null | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[", ]//g')"
    echo "$(ansi 90 "$D_CLI_GLOBAL_NAME-CLI Version") $(ansi 97 "$d_version") $(ansi 90 "Build") $(ansi 97 "$build_id")"

    echo "$(ansi "2;90" "$D_CLI_GLOBAL_NAME-SRC") $(ansi "2;90" "$D_SDK_DIR")"
    echo "$(ansi "2;90" "$D_CLI_GLOBAL_NAME-CTX") $(ansi "2;90" "$D_CTX_DIR")"
}