#!/bin/bash

handle_hook() {
    local HOOK="${1-}"

    # Simple, reliable hook handling system
    # --------------------------------------

    # Exit early if no hook specified
    if [ -z "$HOOK" ]; then
        echo "error: No hook specified. Usage: $0 <hook_name>"
        exit 1
    fi

    # logit 34 "hook" "Executing hook '$HOOK' across workspace"

    # # Execute hook in root repository
    # execute_hook() {
    #     local hook="$1"
        
    #     # Skip if cli_ctx doesn't exist or isn't executable
    #     if [ ! -x "$D_CLI_STUB" ]; then
    #         return 0
    #     fi
        
    #     # # Check if the cli_ctx has a handler for this hook
    #     # (cd "$D_CTX_DIR" && grep -q "hook:$hook" "$D_CLI_STUB") >/dev/null 2>&1
    #     # has_handler=$?
        
    #     # # Skip if no handler found
    #     # if [ $has_handler -ne 0 ]; then
    #     #     # logit 33 "$name" "No handler for 'hook:$hook' found"
    #     #     return 0
    #     # fi
        
    #     # # hook handler found, execute it
    #     # logit 34 "$name" "Executing 'hook:$hook'"
        
    #     # # Execute the command directly without capturing output
    #     # # This allows interactive prompts to work properly
    #     # # Check if the cli_ctx has a handler for this hook (but not commented out)
    #     # # This pattern ensures no # appears before hook:$hook on the same line
    #     # (cd "$D_CTX_DIR" && grep -q "^[^#]*hook:$hook" "$D_CLI_STUB") >/dev/null 2>&1
    #     # has_handler=$?
        
    #     # # Skip if no handler found
    #     # if [ $has_handler -ne 0 ]; then
    #     #     # logit 33 "$name" "No handler for 'hook:$hook' found"
    #     #     return 0
    #     # fi
        
    #     # # hook handler found, execute it
    #     # logit 34 "$name" "Executing 'hook:$hook'"
        
    #     # Execute the command directly without capturing output
    #     # This allows interactive prompts to work properly
    #     cli_ctx "hook:$hook"
    #     rc=$?
    #     # if [ $rc -eq 0 ]; then
    #     #     logit 32 "$name" "hook '$hook' completed successfully"
    #     # else
    #     #     logit 31 "$name" "hook '$hook' failed (exit code $rc)"
    #     # fi
        
    #     return $rc
    # }

    # Execute hook in root repo
    if [ -n "${D_CLI_STUB-}" ] && [ -x "${D_CLI_STUB}" ]; then
        # store set +e state

        local errexit_state="off"
        if [[ "$-" == *e* ]]; then
            errexit_state="on"
            set +e
        fi

        cli_ctx "hook:$HOOK"
        local exit_code=$?

        # restore previous errexit state
        if [ "$errexit_state" = "on" ]; then
            set -e
        fi
    fi

    # logit -o "hook '$HOOK' execution completed"
    return $exit_code
}