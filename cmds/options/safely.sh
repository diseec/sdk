#!/bin/bash

sdk_cmd_opt_safely() {
    mark_ctx_only
    # logit -d "CLI:$D_CLI_CORE:SAFELY:ARGS: $@";

    cli_ctx "$D_SDK_NAME" stop > /dev/null 2>&1 || true ;
    cli_ctx "$D_SDK_NAME" run --quiet "$D_CLI_STUB_CONTAINER" "$@" ; # when non-zero exit code, docker prints a empty line!

    # cli_ctx "$D_SDK_NAME" run "$D_CLI_STUB_CONTAINER" "$@"
    # if [ $? -ne 0 ]; then logit -e "Failed to run command in $D_SDK_NAME container"; fi
}