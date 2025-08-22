#!/bin/bash
set -e
ROOT_DIR="${ROOT_DIR:-$(pwd)}"
EVENT="${1-}"

# Fallback if `message` is not defined; keeps your interface
command -v message >/dev/null 2>&1 || message() { printf "%s: %s\n" "$2" "$3"; }

# Simple, reliable event handling system
# --------------------------------------

# Exit early if no event specified
if [ -z "$EVENT" ]; then
    message 33 "error" "No event specified. Usage: $0 <event_name>"
    exit 1
fi

# message 34 "event" "Executing event '$EVENT' across workspace"

# Execute event in root repository
execute_event() {
    local dir="$1"
    local cli="$2"
    local event="$3"
    local name="$4"
    
    # Skip if CLI doesn't exist or isn't executable
    if [ ! -x "$cli" ]; then
        return 0
    fi
    
    # Check if the CLI has a handler for this event
    (cd "$dir" && grep -q "listen:$event" "$cli") >/dev/null 2>&1
    has_handler=$?
    
    # Skip if no handler found
    if [ $has_handler -ne 0 ]; then
        # message 33 "$name" "No handler for 'listen:$event' found"
        return 0
    fi
    
    # # Event handler found, execute it
    # message 34 "$name" "Executing 'listen:$event'"
    
    # Execute the command directly without capturing output
    # This allows interactive prompts to work properly
    (cd "$dir" && "$cli" "listen:$event")
    rc=$?
    
    # if [ $rc -eq 0 ]; then
    #     message 32 "$name" "Event '$event' completed successfully"
    # else
    #     message 31 "$name" "Event '$event' failed (exit code $rc)"
    # fi
    
    return $rc
}

# Execute event in root repo
if [ -n "${CLI-}" ] && [ -x "$CLI" ]; then
    execute_event "$ROOT_DIR" "$CLI" "$EVENT" "root" || true
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
#     # Skip if CLI doesn't exist or isn't executable
#     if [ ! -x "$cli" ]; then
#         return 0
#     fi
#     # Execute event in module
#     execute_event "$dir" "$cli" "$EVENT" "$module" || true
# }
# # Process all selected modules
# foreach_selected_module_with_callback process_module || true

# message 32 "done" "Event '$EVENT' execution completed"
