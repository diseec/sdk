#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ PROCESSING ANIMATION FUNCTIONS                                          ┃
# ┃ Shows a simple dot animation (., .., ...) while loading                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Global variables to manage loading state, PID, and prefix
PROCESSING_PID=""
PROCESSING_PREFIX=""

# Ensure animation is stopped on parent exit or interrupt
trap 'processing_stop' SIGINT SIGTERM EXIT

processing_start() {
    if [ "$D_GLOB_TTY" != "true" ]; then return 0; fi

    local animation_name="${1:-DOTS}"
    local unique_id="${2:-default}" # Optional unique identifier, defaults to 'default'
    animation_name="$(echo "$animation_name" | tr '[:lower:]' '[:upper:]')"
    processing_stop "$unique_id" # Ensure any existing loader with the same ID is stopped

    # Ensure the cursor is hidden robustly
    if command -v tput > /dev/null; then
        tput civis 2>/dev/null || printf '\033[?25l'
    else
        printf '\033[?25l'
    fi

    local func="sdk_sha_ani_${animation_name}"
    if declare -f "$func" > /dev/null; then
        "$func" "$unique_id"
    else
        sdk_sha_ani_DOTS "$unique_id"
    fi
}

processing_stop() {
    if [ "$D_GLOB_TTY" != "true" ]; then return 0; fi

    local unique_id="${1:-default}" # Optional unique identifier, defaults to 'default'

    if [ -n "$PROCESSING_PID" ] && kill -0 "$PROCESSING_PID" 2>/dev/null; then
        kill "$PROCESSING_PID" 2>/dev/null
        wait "$PROCESSING_PID" 2>/dev/null
        PROCESSING_PID=""

        # Show cursor and clear only the indicator content
        if command -v tput > /dev/null; then
            tput cnorm 2>/dev/null || printf '\033[?25h'
        else
            printf '\033[?25h'
        fi

        printf "\033[s" # Save cursor position
        printf "\033[u" # Restore cursor position
        printf "\033[0K" # Clear from cursor to end of line
        printf "\b \b" # Remove the last character by backspacing and overwriting with a space
    fi
}

###### Different animation styles

sdk_sha_ani_DOTS() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.15
        local max_dots=3
        local dots=1
        local direction=1
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%-$max_dots"s"" "$(printf '%*s' "$dots" | tr ' ' '.')"
            printf " "
            printf "\033[u"
            sleep "$delay"
            if [ $dots -eq $max_dots ]; then
                direction=-1
            elif [ $dots -eq 1 ]; then
                direction=1
            fi
            dots=$((dots + direction))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_SPINNER() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.12
        local frames=("|" "/" "-" "\\")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % 4 ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_BOUNCE() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.09
        local frames=("    ." "   . " "  .  " " .   " ".    " " .   " "  .  " "   . ")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_ARROW() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.13
        local frames=("→" "⇒" "⇨" "⇾" "➔" "➙" "➛" "➜" "➝" "➞" "➟" "➠" "➡" "➢" "➣" "➤" "➥" "➦" "➧" "➨" "➩" "➪" "➫" "➬" "➭" "➮" "➯" "➱" "➲" "➳" "➴" "➵" "➶" "➷" "➸" "➹" "➺" "➻" "➼" "➽" "➾" "➿")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_DOTWAVE() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.11
        local frames=(".    " "..   " "...  " " .... " "  ..." "   .." "    ." "     ")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_BAR() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.10
        local frames=("[    ]" "[=   ]" "[==  ]" "[=== ]" "[ ===]" "[  ==]" "[   =]" "[    ]")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_CIRCLE() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.13
        local frames=("◐" "◓" "◑" "◒")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % 4 ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_CLOCK() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.14
        local frames=("🕛" "🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % 12 ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_PULSE() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.10
        local frames=("░" "▒" "▓" "█" "▓" "▒" "░" " ")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_TRIANGLE() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.13
        local frames=("▲" "▶" "▼" "◀")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % 4 ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_BRAILLE() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.09
        local frames=("⠁" "⠃" "⠇" "⡇" "⣇" "⣧" "⣷" "⣿" "⡿" "⠿" "⠯" "⠟" "⠻" "⠹" "⠸" "⠼" "⠴" "⠤" "⠄" "⠂" "⠁")
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%s" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_BRAILLE_AI_MIXED() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.05

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
        while true; do
            # Randomly switch pattern every full cycle
            if [ $i -eq 0 ]; then
                current_pattern=$((RANDOM % pattern_count))
                IFS=' ' read -r -a frames <<< "${patterns[$current_pattern]}"
                frame_count=${#frames[@]}
            fi
            local color_idx=$((RANDOM % color_count))
            local color=${colors[$color_idx]}
            printf "\r\033[0m\033[%sm%s\033[0m" "$color" "${frames[$i]}"
            sleep "$delay"
            i=$((i+1))
            if [ $i -ge $frame_count ]; then
                i=0
            fi
        done
    ) &
    PROCESSING_PID=$!
}

sdk_sha_ani_AI_WRITING() {
    (
    trap "exit" SIGTERM SIGHUP SIGINT
        local delay=0.05
        local frames=(
            "\033[0;107m \033[0m\033[0m" # Outline reverse
            "\033[7;97m✧\033[0m\033[0m" # Reverse and outline icon
            "\033[7;97m✦\033[0m\033[0m" # Reverse and filled icon
            "\033[1;97m✦\033[0m\033[0m" # Filled icon
            "\033[1;97m✧\033[0m\033[0m" # Outline icon
            "\033[1;90m✧\033[0m\033[0m" # Outline icon
            # "\033[2;97m✧\033[0m\033[0m" # Outline icon
            "\033[2;90m✧\033[0m\033[0m" # Outline icon
            "\033[1;97m \033[0m\033[0m" # Outline icon
            "\033[2;90m✧\033[0m\033[0m" # Outline icon
            # "\033[2;97m✧\033[0m\033[0m" # Outline icon
            "\033[1;90m✧\033[0m\033[0m" # Outline icon
            "\033[1;97m✧\033[0m\033[0m" # Outline icon
            "\033[1;97m✦\033[0m\033[0m" # Filled icon
            "\033[1;97m✧\033[0m\033[0m" # Outline icon
            "\033[7;97m✦\033[0m\033[0m" # Filled reverse
            "\033[7;97m✧\033[0m\033[0m" # Outline reverse
            "\033[0;107m \033[0m\033[0m" # Outline reverse
        )
        local i=0
        printf "\033[s"
        while true; do
            printf "\033[u"
            printf "%b" "${frames[$i]}"
            printf " "
            printf "\033[u"
            sleep "$delay"
            i=$(( (i+1) % ${#frames[@]} ))
        done
    ) &
    PROCESSING_PID=$!
}
