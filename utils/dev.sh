#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ SDK DEVELOPMENT SERVER                                                 ┃
# ┃ Syncs SDK changes to target modules for live development               ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# D_GLOB_LOG_LEVEL="DEBUG"

# Core configuration
WATCH_DIR="$D_SDK_DIR"
TARGET_PATHS=(
    "$D_SDK_DIR/../../node_modules/@diseec/sdk"
    "$D_SDK_DIR/../../services/d0-cms/node_modules/@diseec/sdk"
    "$D_SDK_DIR/../../services/d0-www/node_modules/@diseec/sdk"
)

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ FEATURE DETECTION                                                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check for fswatch for efficient file watching
if command -v fswatch >/dev/null 2>&1; then
    USE_FSWATCH=true
    stdout -s "Using fswatch for faster file monitoring"
else
    USE_FSWATCH=false
    stdout -w "fswatch not found, falling back to polling method"
    stdout -s "For better performance, install fswatch: $(ansi "2;4;90" "brew install fswatch")"
fi

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ SYNC CONFIGURATION                                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Debounce mechanism to prevent multiple syncs in rapid succession
DEBOUNCE_SECONDS=0.5
last_sync_time=0

# Check for GNU parallel for multi-threaded syncing
if command -v parallel >/dev/null 2>&1; then
    USE_PARALLEL=true
    stdout -s "Using GNU parallel for multi-threaded sync"
else
    USE_PARALLEL=false
    stdout -w "GNU parallel not found, using sequential sync"
    stdout -s "For better performance, install parallel: $(ansi "2;4;90" "brew install parallel")"
fi

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ CORE FUNCTIONS                                                          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Sync SDK files to all target paths
sync_files() {
    # Pause status line updates during sync
    STATUS_LINE_ACTIVE=false
    
    # Save cursor position, move up one line and clear it
    printf "\033[s\033[1A\r\033[K"
    
    local start_time=$(date +%s.%N)
    local changes_detected="Changes applied"
    
    # Use parallel processing for multiple targets if available
    if [ "$USE_PARALLEL" = true ]; then
        export WATCH_DIR 
        printf '%s\n' "${TARGET_PATHS[@]}" | parallel --will-cite 'mkdir -p {} && rsync -a --delete "$WATCH_DIR/" {}/' > /dev/null 2>&1
        
        # Check for overall success
        if [ $? -ne 0 ]; then
            changes_detected="$changes_detected (with errors)"
        fi
    else
        local sync_success=true
        
        for TARGET in "${TARGET_PATHS[@]}"; do
            mkdir -p "$TARGET"
            # Using rsync for efficient differential copying
            rsync -a --delete "$WATCH_DIR/" "$TARGET/" > /dev/null 2>&1 
            
            if [ $? -ne 0 ]; then
                sync_success=false
                changes_detected="$changes_detected (with errors)"
                break
            fi
        done
    fi
    
    # Calculate and display elapsed time
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    elapsed=$(printf "%.1f" $elapsed)
    
    # Store the sync info in variables for status display
    LAST_SYNC_MESSAGE="${changes_detected} (${elapsed}s)"
    LAST_SYNC_TIME=$(date +%s)
    
    # Restore cursor position
    printf "\033[u"
    
    # Resume status updates
    STATUS_LINE_ACTIVE=true
    # echo
    # display_status
    # echo
}

# Generate checksum of watched directory for change detection
get_checksum() {
    find "$WATCH_DIR" -type f -exec md5sum {} \; | sort | md5sum
}

# Clean shutdown handler for graceful termination
cleanup() {
    echo
    echo
    stdout -w "$(ansi "97" "Sync server stopped.")" 
    stdout -i --processing "Cleaning up background processes"
    
    # Kill any background processes we started
    jobs -p | xargs -r kill 2>/dev/null
    
    # Final message before exit
    stdout -s "Development session ended"
    exit 0
}

# Register signal handlers
trap cleanup SIGINT SIGTERM

# Display startup banner
echo
printf "\033[1;97m$(ansi "1;97" "$(capitalize $D_ORG_NAME) SDK Development Server") $(ansi "2;90" "v${D_VERSIONONON:-1.0.0}")\033[0m\n"
echo

# Display startup information
stdout -s "Started development server"
stdout -s "Watching for changes in $(ansi "97" "$WATCH_DIR")"
stdout -s "Syncing to $(ansi "1;97" "${#TARGET_PATHS[@]}") target locations"

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ WATCH IMPLEMENTATION                                                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Initialize stats for reporting
SYNC_COUNT=0
START_TIME=$(date +%s)

# Status variables
LAST_SYNC_MESSAGE=""
LAST_SYNC_TIME=""
STATUS_LINE_ACTIVE=true

# Status display function - shows periodic status update
display_status() {
    # Don't update during sync operations
    if [ "$STATUS_LINE_ACTIVE" = false ]; then
        return
    fi
    
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    local runtime=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)
    local timestamp=$(date +"%H:%M:%S")

    # Clear previous line and prepare for new status
    printf "\r\033[K"
    
    # Show timestamp and status information
    printf "Uptime: \033[1;97m%s\033[0m | Syncs: \033[1;97m%d\033[0m" "$runtime" "$SYNC_COUNT"
    
    # Add sync notification if recent
    if [ -n "$LAST_SYNC_MESSAGE" ] && [ -n "$LAST_SYNC_TIME" ]; then
        local time_since_sync=$((current_time - LAST_SYNC_TIME))
        if [ $time_since_sync -lt 8 ]; then
            # Show sync message for 8 seconds then fade out
             # Animation based on time since last sync
            local sync_icon
            case $((time_since_sync % 4 )) in
                0) sync_icon="█" ;; 
                1) sync_icon="▓" ;;
                2) sync_icon="▒" ;; 
                3) sync_icon="░" ;;
            esac 
            
            printf " | \033[1;30m%s %s\033[0m" "$sync_icon" "$LAST_SYNC_MESSAGE"
        fi
    fi
}

# Wait for initialization to complete before starting status updates
sleep 1

# Schedule status updates in background
(
    while true; do
        sleep 1
        kill -USR1 $$ 2>/dev/null
    done
) &
STATUS_PID=$!

# Status update on signal
trap display_status USR1

# Move cursor to the beginning of the line and clear it
printf "\r\033[K"

# Setup for status line - create a dedicated line
printf "\n"

# Set cursor to hidden for cleaner display
printf "\033[?25l"

if [ "$USE_FSWATCH" = true ]; then
    # ────────────────────────────────────────────────────────────────────────────
    # Event-based file monitoring with fswatch
    # ────────────────────────────────────────────────────────────────────────────
    stdout -s "Starting event-based file monitoring"
    
    fswatch -0 -r "$WATCH_DIR" | while read -d "" event; do
        # Calculate time since last sync for debounce
        current_time=$(date +%s.%N)
        time_diff=$(echo "$current_time - $last_sync_time" | bc)
        
        # Only sync if we've waited for the debounce period
        if (( $(echo "$time_diff > $DEBOUNCE_SECONDS" | bc -l) )); then
            sync_files
            last_sync_time=$current_time
            SYNC_COUNT=$((SYNC_COUNT + 1))
        fi
    done
else
    # ────────────────────────────────────────────────────────────────────────────
    # Fallback polling-based file monitoring
    # ────────────────────────────────────────────────────────────────────────────
    stdout -s "Starting polling-based file monitoring"
    
    last_checksum=$(get_checksum)
    
    while true; do
        # Check for file changes
        sleep 1
        new_checksum=$(get_checksum)

        if [ "$new_checksum" != "$last_checksum" ]; then
            # Calculate time since last sync for debounce
            current_time=$(date +%s.%N)
            time_diff=$(echo "$current_time - $last_sync_time" | bc)
            
            # Only sync if we've waited for the debounce period
            if (( $(echo "$time_diff > $DEBOUNCE_SECONDS" | bc -l) )); then
                sync_files
                last_sync_time=$current_time
                SYNC_COUNT=$((SYNC_COUNT + 1))
            fi
            last_checksum=$new_checksum
        fi
    done
fi

# Clean up on exit
cleanup_and_exit() {
    # Show cursor again
    printf "\033[?25h"
    
    # Kill background process
    kill $STATUS_PID 2>/dev/null
    
    # Clear status line
    printf "\r\033[K"
    
    # Call main cleanup
    cleanup
}

# Register exit handler
trap cleanup_and_exit EXIT
