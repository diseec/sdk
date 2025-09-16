#!/bin/bash

sdk_cmd_opt_help() {
display_help "" "" \
"$(ansi "1;90" "$(capitalize 'Usage')")                        " "$D_CLI_GLOBAL_NAME/(bash $D_CLI_LOCAL_NAME) [opts] <cmd> <sub-cmd> [opts] [args]" \
"                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$D_ORG_NAME/$D_SDK_NAME")")" \
"$(ansi "1;90" "$(capitalize '[Global Options]')")             " "" \
"                             " "" \
"    -p|--patch               " "Force pull and reinstall $D_SDK_NAME into project" \
"                             " "$(ansi "2;90" "Ensures a fresh $D_SDK_NAME binary is used,")" \
"                             " "$(ansi "2;90" "when the local $D_SDK_NAME is missing, corrupted,")" \
"                             " "$(ansi "2;90" "or unable to bootstrap the CLI itself")" \
"    -s|--safely              " "Safe command execution, (in $D_SDK_NAME container!)" \
"    -r|--recursive           " "Recurse actions into submodules" \
"                             " "$(ansi "2;90" "Not supported by all commands, check command help")" \
"    -q|--quiet               " "Suppress all output" \
"    -v|--verbose             " "Set log level to VERBOSE (most detailed)" \
"    --log-level              " "Set the log level for the CLI" \
"                             " "$(ansi "2;90" "Valid values: VERBOSE, INFO, WARNING, ERROR")" \
"    --no-tty                 " "Disable TTY detection (force non-interactive mode)" \
"    --version                " "Show version information" \
"    -d|--debug               " "Enable debug mode: tracing and verbose logging" \
"    -h|--help                " "Brief usage and docs information" \
"" "" "$(ansi "1;90" "$(capitalize 'Project Management')")" "" \
"    ins|install              " "Install project dependencies and tools" \
"    ude|update               " "Update CLI and sync project" \
"    sta|status               " "Show comprehensive project status" \
"" "" "$(ansi "1;90" "$(capitalize 'Workflow & Environment')")" "" \
"    dai|daily                " "$(ansi 36 '✦') $(ansi 90 'Generate daily insights')" \
"    dev|develop              " "Start development environment" \
"    bpa|build                " "Build project images" \
"    run                      " "Execute command in container" \
"    exe|execute              " "Execute command in specific service" \
"    she|shell                " "Open interactive shell" \
"    tes|test                 " "Run test suites" \
"    for|format               " "Format codebase" \
"" "" "$(ansi "1;90" "$(capitalize 'Source Control')")" "" \
"    git                      " "Git workflow management" \
"    pul|pull                 " "Pull and merge latest changes" \
"    pus|push                 " "$(ansi 96 '✦') $(ansi 90 'Auto-commit and create PR')" \
"" "" "$(ansi "1;90" "$(capitalize 'Infrastructure')")" "" \
"    doc|docker               " "Docker operations" \
"" "" "$(ansi "1;90" "$(capitalize 'Configuration')")" "" \
"    con|config               " "Configuration management" \
"    sub|submodule            " "Unified submodule management (packages & services)" \
"    sec|secret               " "Encrypted secrets management" \
"" "" "$(ansi "1;90" "$(capitalize 'Utilities')")" "" \
"    ai$(printf "\033[96m✦\033[0m\033[34m")                      " "Access to a comprehensive set of AI utils" \
"    api                      " "API operations" \
"    $D_SDK_NAME                      " "$(capitalize $D_SDK_NAME) internal operations" \
"    env|envs                 " "Manage environment variables. Examples:" \
"                             " "$(ansi "2;90" '$ set -a && eval $('$D_CLI_GLOBAL_NAME envs') && set +a')" \
"                             " "$(ansi "2;90" '$ eval $(cli_ctx envs) > /dev/null')" \
"                             " "$(ansi "2;90" '$ bash '$D_SDK_NAME' envs >> $GITHUB_ENV')" \
"    abo|about                " "About $D_SDK_NAME, authors, $D_ORG_NAME, policies and licensing" \
"$@"
}
