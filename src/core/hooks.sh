#!/bin/bash

cor_fire_hook() {
    set -e
    ROOT_DIR="${ROOT_DIR:-$(pwd)}"
    HOOK="${1-}"

    # Fallback if `message` is not defined; keeps your interface
    command -v message >/dev/null 2>&1 || message() { printf "%s: %s\n" "$2" "$3"; }

    # Simple, reliable hook handling system
    # --------------------------------------

    # Exit early if no hook specified
    if [ -z "$HOOK" ]; then
        message 33 "error" "No hook specified. Usage: $0 <hook_name>"
        exit 1
    fi

    # message 34 "hook" "Executing hook '$HOOK' across workspace"

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
        (cd "$dir" && grep -q "listen:$hook" "$cli") >/dev/null 2>&1
        has_handler=$?
        
        # Skip if no handler found
        if [ $has_handler -ne 0 ]; then
            # message 33 "$name" "No handler for 'listen:$hook' found"
            return 0
        fi
        
        # # hook handler found, execute it
        # message 34 "$name" "Executing 'listen:$hook'"
        
        # Execute the command directly without capturing output
        # This allows interactive prompts to work properly
        # Check if the cli_main has a handler for this hook (but not commented out)
        # This pattern ensures no # appears before listen:$hook on the same line
        (cd "$dir" && grep -q "^[^#]*listen:$hook" "$cli") >/dev/null 2>&1
        has_handler=$?
        
        # Skip if no handler found
        if [ $has_handler -ne 0 ]; then
            # message 33 "$name" "No handler for 'listen:$hook' found"
            return 0
        fi
        
        # # hook handler found, execute it
        # message 34 "$name" "Executing 'listen:$hook'"
        
        # Execute the command directly without capturing output
        # This allows interactive prompts to work properly
        (cd "$dir" && "$cli" "listen:$hook")
        rc=$?
        # if [ $rc -eq 0 ]; then
        #     message 32 "$name" "hook '$hook' completed successfully"
        # else
        #     message 31 "$name" "hook '$hook' failed (exit code $rc)"
        # fi
        
        return $rc
    }

    # Execute hook in root repo
    if [ -n "${cli_main-}" ] && [ -x cli_main ]; then
        execute_hook "$ROOT_DIR" cli_main "$HOOK" "root" || true
    fi

    # # Process each selected module
    # process_module() {
    #     local module="$1"
    #     local module_path="$2"
    #     local dir="$ROOT_DIR/$module_path"
    #     local cli="$dir/cli"
    #     # Skip if directory doesn't exist
    #     if [ ! -d "$dir" ]; then
    #         return 0
    #     fi
    #     # Skip if cli_main doesn't exist or isn't executable
    #     if [ ! -x "$cli" ]; then
    #         return 0
    #     fi
    #     # Execute hook in module
    #     execute_hook "$dir" "$cli" "$HOOK" "$module" || true
    # }
    # # Process all selected modules
    # fac_wor_foreach_selected_module process_module || true

    # message 32 "done" "hook '$HOOK' execution completed"
}