#!/bin/bash

sdk_cmd_opt_help() {
display_help "" "" \
"$(ansi "1;90" "$(capitalize 'Usage')")                        " "[$D_CLI_GLOBAL_NAME]/[bash $D_CLI_LOCAL_NAME] [command] [subcommand] [options] [arguments]" \
"                             " "$(ansi "2;90" "Documentation at $(ansi "2;4;90" "https://github.com/$D_ORG_NAME/$D_SDK_NAME")")" \
"" "" "$(ansi "1;90" "$(capitalize "Global Manager The '$D_CLI_GLOBAL_NAME'")")" "" \
"    $D_CLI_GLOBAL_NAME [option] [arguments]   " "Locate project root and invoke the project's ./$D_CLI_LOCAL_NAME" \
"        about                " "About $D_SDK_NAME, authors, $D_ORG_NAME, policies and licensing" \
"    $(ansi 90 'Options:')" "" \
"        --patch              " "Force pull and reinstall sdk into project" \
"                             " "$(ansi "2;90" "Ensures a fresh sdk binary is used,")" \
"                             " "$(ansi "2;90" "when the local sdk is missing, corrupted,")" \
"                             " "$(ansi "2;90" "or unable to bootstrap the CLI itself.")" \
"        --log-level          " "Set the log level for the CLI, valid values: DEBUG, INFO, WARNING, ERROR" \
"        --version            " "Show version information" \
"        --safely|-s          " "Safe command execution" \
"        --help|-h            " "Brief usage and docs information" \
"" "" "$(ansi "1;90" "$(capitalize 'Project Management')")" "" \
"    ins|install              " "Install project dependencies and tools" \
"    ude|update               " "Update cli_ctx and sync project" \
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
"    wor|workspace            " "Workspace configuration" \
"    con|config               " "Configuration management" \
"    set|settings             " "Settings operations" \
"    sub|submodule            " "Unified submodule management (packages & services)" \
"    sec|secret               " "Encrypted secrets management" \
"" "" "$(ansi "1;90" "$(capitalize 'Utilities')")" "" \
"    ai$(printf "\033[96m✦\033[0m\033[34m")                      " "Access to a comprehensive set of AI utils" \
"    env|envs                 " "Manage environment variables. Examples:" \
"                             " "$(ansi "2;90" 'set -a; eval "$($D_CLI_GLOBAL_NAME envs)"; set +a')" \
"                             " "$(ansi "2;90" 'eval "$(cli_ctx envs)" > /dev/null')" \
"    api                      " "API operations" \
"    sdk                      " "SDK container operations" \
"$@"
}
