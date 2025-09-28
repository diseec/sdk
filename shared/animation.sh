#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ PROCESSING ANIMATION FUNCTIONS                                          ┃
# ┃ Shows an animation in the first slot of stdout that auto-stops          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Global variables to manage loading state and animation
PROCESSING_PID=""
PROCESSING_DETECTOR_PID=""
PROCESSING_ANIMATION_RUNNING=false
PROCESSING_ACTIVE=false

# Ensure animation is stopped on parent exit or interrupt
trap 'processing_stop >&2' SIGINT SIGTERM EXIT

# Main public function - Start an animation that auto-stops on output
# Usage: processing_start [ANIMATION_TYPE]
processing_start() {
    if [ "$D_GLOB_TTY" != "true" ] || [ "$D_GLOB_LOG_LEVEL" = "QUIET" ]; then return 0; fi
    
    # Clean up any existing animation first
    processing_stop >&2
    
    # Mark animation as active
    PROCESSING_ACTIVE=true
    PROCESSING_ANIMATION_RUNNING=true
    
    # Get animation type
    local animation_type="${1:-BRAILLE_MIXED}"
    animation_type="$(echo "$animation_type" | tr '[:lower:]' '[:upper:]')"
    
    # # Hide cursor - multiple methods for reliability
    # printf "\033[?25l" # ANSI escape sequence
    
    # Start the animation in background - we'll create a new animation line
    local func="sdk_sha_ani_${animation_type}"
    if declare -f "$func" > /dev/null; then
        "$func" >&2
    else
        sdk_sha_ani_BRAILLE_MIXED >&2
    fi
    
    # Setup auto-stop detector in background
    (
        trap "exit" SIGTERM SIGHUP SIGINT
        while [ "$PROCESSING_ANIMATION_RUNNING" = true ]; do
            sleep 0.2
            
            # Check if parent process has terminated
            if ! ps | grep -q " $$ "; then
                PROCESSING_ANIMATION_RUNNING=false
                processing_stop >&2
                break
            fi
        done
    ) &
    
    PROCESSING_DETECTOR_PID=$!
}

# Internal function to stop any running animation
# Usage: processing_stop
processing_stop() {
    if [ "$D_GLOB_TTY" != "true" ] || [ "$D_GLOB_LOG_LEVEL" = "QUIET" ]; then return 0; fi
    
    # Set flags first to prevent race conditions
    PROCESSING_ANIMATION_RUNNING=false
    PROCESSING_ACTIVE=false
    
    # Kill animation process
    if [ -n "$PROCESSING_PID" ] && kill -0 "$PROCESSING_PID" 2>/dev/null; then
        kill -TERM "$PROCESSING_PID" 2>/dev/null
        wait "$PROCESSING_PID" 2>/dev/null || true
        PROCESSING_PID=""
    fi
    
    # Kill detector process
    if [ -n "$PROCESSING_DETECTOR_PID" ] && kill -0 "$PROCESSING_DETECTOR_PID" 2>/dev/null; then
        kill -TERM "$PROCESSING_DETECTOR_PID" 2>/dev/null
        wait "$PROCESSING_DETECTOR_PID" 2>/dev/null || true
        PROCESSING_DETECTOR_PID=""
    fi
    
    # # More aggressive cleanup to prevent leftover characters
    # sleep 0.05  # Small delay to ensure processes are stopped
    
    # # Clear only the animation character at current position
    # printf " \b"
    
    # # Restore cursor visibility with multiple methods for redundancy
    # printf "\033[?25h"         # ANSI escape sequence
    # printf "\033[34h\033[?25h" # Alternative sequence
    # echo -en "\e[?12l\e[?25h"  # Another alternative
    
    # # Force cursor visibility on exit
    # trap 'printf "\033[?25h"' EXIT
}

###### Different animation styles

sdk_sha_ani_BRAILLE_MIXED() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.05
        local animationLine=""

        # Cache the generated colors array
        if [ -z "${BRAILLE_ANIME_CACHED_COLORS+x}" ]; then
            # Define the colors and their repetition counts
            local color_repeats=(
                97:75  # white
                36:15  # clay
                31:3   # red
                32:1   # green
                33:1   # yellow
                34:10   # blue
                35:5   # magenta
            )

            # Generate the colors array dynamically
            local colors=()
            for entry in "${color_repeats[@]}"; do
                IFS=':' read -r color count <<< "$entry"
                for ((i = 0; i < count; i++)); do
                    colors+=("$color")
                done
            done

            # Cache the result
            BRAILLE_ANIME_CACHED_COLORS=("${colors[@]}")
        else
            # Use the cached colors
            local colors=("${BRAILLE_ANIME_CACHED_COLORS[@]}")
        fi

        local patterns=(
            "⠁ ⠂ ⠄ ⠤ ⠴ ⠼ ⠸ ⠹ ⠻ ⠟ ⠯ ⠿ ⡿ ⣿ ⣷ ⣧ ⣇ ⡇ ⠇ ⠃ ⠁" # forward
            "⠁ ⠃ ⠇ ⡇ ⣇ ⣧ ⣷ ⣿ ⡿ ⠿ ⠯ ⠟ ⠻ ⠹ ⠸ ⠼ ⠴ ⠤ ⠄ ⠂ ⠁" # reverse
            "⠁ ⠂ ⠄ ⠤ ⠴ ⠼ ⠸ ⠹ ⠸ ⠼ ⠴ ⠤ ⠄ ⠂ ⠁" # zig-zag
            "⠁ ⠃ ⠇ ⡏ ⣏ ⣟ ⣿ ⣿ ⣟ ⣏ ⡏ ⠇ ⠃ ⠁" # pulse
            "⠁ ⠂ ⠄ ⠈ ⠐ ⠠ ⡀ ⢀ ⢀ ⡀ ⠠ ⠐ ⠈ ⠄ ⠂ ⠁" # zigzag diagonal
            "⠁ ⠂ ⠄ ⠆ ⠒ ⠲ ⠶ ⡶ ⣶ ⣿ ⣷ ⣶ ⡶ ⠶ ⠲ ⠒ ⠆ ⠄ ⠂ ⠁" # ripple
            "⠁ ⠂ ⠄ ⠆ ⠇ ⠏ ⠟ ⠿ ⡿ ⣟ ⣯ ⣷ ⣿ ⣷ ⣯ ⣟ ⡿ ⠿ ⠟ ⠏ ⠇ ⠆ ⠄ ⠂ ⠁" # vortex
            "⠁ ⠂ ⠄ ⠆ ⠒ ⠤ ⠦ ⠶ ⡶ ⣶ ⣿ ⣷ ⣶ ⡶ ⠶ ⠦ ⠤ ⠒ ⠆ ⠄ ⠂ ⠁" # spiral wave
            "⠁ ⠂ ⠆ ⠒ ⠤ ⠴ ⠶ ⡶ ⣶ ⣿ ⣷ ⣧ ⡇ ⠇ ⠃ ⠁" # cascade
            "⠁ ⠂ ⠄ ⠆ ⠒ ⠲ ⠴ ⠤ ⠒ ⠆ ⠄ ⠂ ⠁" # comet
            "⠁ ⠃ ⠇ ⡏ ⠐ ⠒ ⠖ ⡞ ⡞ ⠖ ⠒ ⠐ ⡏ ⠇ ⠃ ⠁" # wave horizontal
            "⠁ ⠂ ⠄ ⠈ ⠐ ⠄ ⠠ ⠠ ⠄ ⠐ ⡀ ⢀ ⠈ ⠂ ⠁" # spiral
        )
        local pattern_count=${#patterns[@]}
        local color_count=${#colors[@]}
        local current_pattern=0
        local frames=()
        local frame_count=0
        local i=0
        
        while [ "$PROCESSING_ANIMATION_RUNNING" = true ]; do
            # Randomly switch pattern every full cycle
            if [ $i -eq 0 ]; then
                current_pattern=$((RANDOM % pattern_count))
                IFS=' ' read -r -a frames <<< "${patterns[$current_pattern]}"
                frame_count=${#frames[@]}
            fi
            
            local color_idx=$((RANDOM % color_count))
            local color=${colors[$color_idx]}
            
            # Write animation character, then backspace to overwrite next time
            printf "\033[%sm%s\033[0m\b" "$color" "${frames[$i]}"
            
            sleep "$delay"
            i=$((i+1))
            if [ $i -ge $frame_count ]; then
                i=0
            fi
            
            # Check if we need to exit
            if [ "$PROCESSING_ANIMATION_RUNNING" != "true" ]; then
                # Just stop, don't clear - parent will handle cleanup
                break
            fi
        done
        
        # No cleanup needed - parent handles it
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_AI_WRITING() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.1
        
        local frames=(
            "\033[0;107m \033[0m\033[0m" # Outline reverse
            "\033[7;97m✧\033[0m\033[0m" # Reverse and outline icon
            "\033[7;97m✦\033[0m\033[0m" # Reverse and filled icon
            "\033[1;97m✦\033[0m\033[0m" # Filled icon
            "\033[1;97m✧\033[0m\033[0m" # Outline icon
            "\033[1;90m✧\033[0m\033[0m" # Outline icon
            "\033[2;97m✧\033[0m\033[0m" # Outline icon
            "\033[2;90m✧\033[0m\033[0m" # Outline icon
            "\033[1;97m \033[0m\033[0m" # Outline icon
            "\033[2;90m✧\033[0m\033[0m" # Outline icon
            "\033[2;97m✧\033[0m\033[0m" # Outline icon
            "\033[1;90m✧\033[0m\033[0m" # Outline icon
            "\033[1;97m✧\033[0m\033[0m" # Outline icon
            "\033[1;97m✦\033[0m\033[0m" # Filled icon
            "\033[1;97m✧\033[0m\033[0m" # Outline icon
            "\033[7;97m✦\033[0m\033[0m" # Filled reverse
            "\033[7;97m✧\033[0m\033[0m" # Outline reverse
            "\033[0;107m \033[0m\033[0m" # Outline reverse
        )
        local i=0
        
        while [ "$PROCESSING_ANIMATION_RUNNING" = true ]; do
            # Write animation character, then backspace to overwrite next time
            printf "%b\b" "${frames[$i]}"
            
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
            
            # Check if we need to exit
            if [ "$PROCESSING_ANIMATION_RUNNING" != "true" ]; then
                # Just stop, don't clear - parent will handle cleanup
                break
            fi
        done
        
        # No cleanup needed - parent handles it
    ) &
    PROCESSING_PID=$!
}
