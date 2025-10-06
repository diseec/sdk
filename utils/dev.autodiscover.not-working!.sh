#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ SDK DEVELOPMENT SERVER                                                  ┃
# ┃ Syncs SDK changes to target modules for live development                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# D_LOG_LEVEL="DEBUG"

# Core configuration
WATCH_DIR="$D_SDK_DIR"

# Find the root git repository
find_git_root() {
    local current_dir="$1"
    while [[ "$current_dir" != "/" ]]; do
        
        if [[ -e "$current_dir/.git" ]]; then
            if [ "$current_dir" = "$1" ]; then
                current_dir="$(dirname "$current_dir")"
                continue
            fi
            echo "$current_dir"
            return 0
        fi

        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# Find all git repositories and their node_modules/@diseec/sdk paths
find_target_paths() {
    local root_dir="$(find_git_root "$WATCH_DIR")"
    if [[ -z "$root_dir" ]]; then
        stdout -e "No git repository found in parent directories"
        exit 1
    fi

    # Create array for storing results
    local -a target_paths=()

    # First, quickly find all package.json files
    stdout -s --processing "Scanning workspace"
    local package_files
    package_files=$(find "$root_dir" -type f -name "package.json" ! -path "*/node_modules/*" 2>/dev/null)
    
    if [ -z "$package_files" ]; then
        stdout -w "No package.json files found"
        exit 1
    fi

    # Convert to array and get count
    local -a pkg_files
    readarray -t pkg_files <<< "$package_files"
    local total_files=${#pkg_files[@]}
    local current=0

    # Process each package.json
    for pkg_file in "${pkg_files[@]}"; do
        current=$((current + 1))
        # Skip empty lines
        [ -z "$pkg_file" ] && continue
        
        local pkg_dir="$(dirname "$pkg_file")"
        local sdk_path="$pkg_dir/node_modules/@diseec/sdk"

        # Update progress (only every 5th file to reduce screen flicker)
        if ((current % 5 == 0)) || ((current == total_files)); then
            printf "\r\033[K\033[90mAnalyzing projects... %d/%d\033[0m" "$current" "$total_files"
        fi

        # Quick check for @diseec/sdk in package.json
        if [[ -e "$pkg_dir/.git" || -e "$(dirname "$pkg_dir")/.git" ]]; then
            if [ -f "$pkg_file" ] && grep -q '"@diseec/sdk"\|"@diseec/sdk"\|"@diseec/sdk"' "$pkg_file" 2>/dev/null; then
                target_paths+=("$sdk_path")
            fi
        fi
    done
    printf "\r\033[K"  # Clear the progress line

    # Print found paths with status
    echo
    stdout "━━ TARGET PROJECTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ((${#target_paths[@]} == 0)); then
        stdout -w "No Node.js projects with @diseec/sdk found in git repositories"
        exit 1
    fi

    stdout "Found $(ansi 97 "${#target_paths[@]}") projects to sync:"
    echo
    
    # Display paths with status indicators
    for path in "${target_paths[@]}"; do
        local rel_path="${path#$root_dir/}"
        # Check if target exists
        if [ -d "$path" ]; then
            stdout --ansi="$TESTER_COLOR_DIM" "  $(ansi 32 "✓") $(ansi 97 "$rel_path")"
        else
            stdout --ansi="$TESTER_COLOR_DIM" "  $(ansi 33 "⦿") $(ansi 97 "$rel_path") $(ansi 33 "(will be created)")"
        fi
    done
    echo

    # Return the found paths
    printf '%s\n' "${target_paths[@]}"

    # Read unique paths into array
    local target_paths=()
    while IFS= read -r path; do
        target_paths+=("$path")
    done < <(sort -u "$temp_file")

    if [[ ${#target_paths[@]} -eq 0 ]]; then
        stdout -w "No Node.js projects with @diseec/sdk found in git repositories"
        exit 1
    fi

    # Print found paths with status
    echo
    stdout "\n━━ TARGET PROJECTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    stdout "Found $(ansi 97 "${#target_paths[@]}") projects to sync:"
    echo
    
    # Calculate the longest path for alignment
    local max_length=0
    for path in "${target_paths[@]}"; do
        local rel_path="${path#$root_dir/}"
        if [ ${#rel_path} -gt $max_length ]; then
            max_length=${#rel_path}
        fi
    done
    
    # Display paths in columns with status indicators
    for path in "${target_paths[@]}"; do
        local rel_path="${path#$root_dir/}"
        # Check if target exists
        if [ -d "$path" ]; then
            stdout --ansi="$TESTER_COLOR_DIM" "  $(ansi 32 "✓") $(ansi 97 "$rel_path")"
        else
            stdout --ansi="$TESTER_COLOR_DIM" "  $(ansi 33 "⦿") $(ansi 97 "$rel_path") $(ansi 33 "(will be created)")"
        fi
    done
    echo

    printf '%s\n' "${target_paths[@]}"
}

# Display startup banner first
echo
printf "\033[1;97m$(ansi "1;97" "$(capitalize $D_ORG_NAME) SDK Development Server") $(ansi "2;90" "v${D_VERSIONONON:-1.0.0}")\033[0m\n"
echo

# Initialize target paths
TARGET_PATHS=($(find_target_paths))

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ FEATURE DETECTION                                                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check for fswatch for efficient file watching
if command -v fswatch >/dev/null 2>&1; then
    USE_FSWATCH=true
else
    USE_FSWATCH=false
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
else
    USE_PARALLEL=false
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
        export changes_detected
        printf '%s\n' "${TARGET_PATHS[@]}" | parallel --will-cite '
            if mkdir -p "{}" 2>/dev/null; then
                if ! rsync -a --delete "$WATCH_DIR/" "{}/"; then
                    echo "Failed to sync: {}" >&2
                    exit 1
                fi
            else
                echo "Failed to create directory: {}" >&2
                exit 1
            fi
        ' 2>/dev/null
        
        # Check for overall success
        if [ $? -ne 0 ]; then
            changes_detected="$changes_detected (with errors)"
        fi
    else
        local sync_success=true
        local error_msg=""
        
        for TARGET in "${TARGET_PATHS[@]}"; do
            if ! mkdir -p "$TARGET" 2>/dev/null; then
                sync_success=false
                error_msg="Failed to create directory: $TARGET"
                break
            fi
            
            # Using rsync for efficient differential copying
            if ! rsync -a --delete "$WATCH_DIR/" "$TARGET/" 2>/dev/null; then
                sync_success=false
                error_msg="Failed to sync: $TARGET"
                break
            fi
        done
        
        if [ "$sync_success" = false ]; then
            changes_detected="$changes_detected (Error: $error_msg)"
        fi
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
echo
stdout "━━ SERVER STATUS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
stdout "State:   $(ansi "32" "Active")"
stdout "Source:  $(ansi "97" "$WATCH_DIR")"
stdout "Method:  $(ansi "97" "$([ "$USE_FSWATCH" = true ] && echo "Event-based (fswatch)" || echo "Polling-based")")"
stdout "Targets: $(ansi "97" "${#TARGET_PATHS[@]}") projects"

# Show optimization suggestions
if [ "$USE_FSWATCH" = false ]; then
    stdout -w "File monitoring: $(ansi "33" "Using fallback polling method")"
    stdout "  → Install fswatch for better performance: $(ansi "2;4;90" "brew install fswatch")"
fi

if [ "$USE_PARALLEL" = false ]; then
    stdout -w "Sync method:     $(ansi "33" "Using sequential sync")"
    stdout "  → Install GNU parallel for faster syncing: $(ansi "2;4;90" "brew install parallel")"
fi
echo

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
