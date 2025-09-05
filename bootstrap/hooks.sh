#!/bin/bash

handle_hook() {
    set -e
    local HOOK="${1-}"

    # Simple, reliable hook handling system
    # --------------------------------------

    # Exit early if no hook specified
    if [ -z "$HOOK" ]; then
        echo "error: No hook specified. Usage: $0 <hook_name>"
        exit 1
    fi

    # logit 34 "hook" "Executing hook '$HOOK' across workspace"

    # Execute hook in root repository
    execute_hook() {
        local dir="$1"
        local cli="$2"
        local hook="$3"
        local name="$4"
        
        # Skip if cli_main doesn't exist or isn't executable
        if [ ! -x "$cli" ]; then
            return 0
        fi
        
        # Check if the cli_main has a handler for this hook
        (cd "$dir" && grep -q "hook:$hook" "$cli") >/dev/null 2>&1
        has_handler=$?
        
        # Skip if no handler found
        if [ $has_handler -ne 0 ]; then
            # logit 33 "$name" "No handler for 'hook:$hook' found"
            return 0
        fi
        
        # # hook handler found, execute it
        # logit 34 "$name" "Executing 'hook:$hook'"
        
        # Execute the command directly without capturing output
        # This allows interactive prompts to work properly
        # Check if the cli_main has a handler for this hook (but not commented out)
        # This pattern ensures no # appears before hook:$hook on the same line
        (cd "$dir" && grep -q "^[^#]*hook:$hook" "$cli") >/dev/null 2>&1
        has_handler=$?
        
        # Skip if no handler found
        if [ $has_handler -ne 0 ]; then
            # logit 33 "$name" "No handler for 'hook:$hook' found"
            return 0
        fi
        
        # # hook handler found, execute it
        # logit 34 "$name" "Executing 'hook:$hook'"
        
        # Execute the command directly without capturing output
        # This allows interactive prompts to work properly
        cd "$dir" && "$cli" "hook:$hook"
        rc=$?
        # if [ $rc -eq 0 ]; then
        #     logit 32 "$name" "hook '$hook' completed successfully"
        # else
        #     logit 31 "$name" "hook '$hook' failed (exit code $rc)"
        # fi
        
        return $rc
    }

    # Execute hook in root repo
    if [ -n "${D_CLI_MAIN-}" ] && [ -x "${D_CLI_MAIN}" ]; then
        execute_hook "$D_CTX_DIR" "$D_CLI_MAIN" "$HOOK" "root" || true
    fi

    # logit -o "hook '$HOOK' execution completed"
}