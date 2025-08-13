#!/bin/sh

. $CLI_ROOT/index.sh;

# Quietly check for version changes (don't display messages)
check_for_updates() {
    # Skip if we're just running version or help commands
    if [ "$command" = "version" ] || [ "$command" = "--version" ] || [ "$command" = "help" ] || [ "$command" = "sync" ]; then
        return 0
    fi
    
    # Load workspace functions without displaying messages
    . $CLI_SRC/workspace.sh
    
    # Check if version changed
    if has_version_changed; then
        message 33 "UPDATE" "Devops tool update detected! Current version: $VERSION"
        message 33 "UPDATE" "Run 'cli sync' to update your workspace configuration"
    fi
}

command=$1; shift; case $command in
    workspace) cmd_workspace "$@" ;;
    version|--version) cmd_version "$@" ;;
    envs)
        # Source projects root cli to load environment variables. example: "source ./cli envs;"
        message 34 "info" "Sourced repo envs"
    ;;
    *) 
        # Check for updates quietly
        check_for_updates
        cmd_unknown "$@" 
    ;;
esac
