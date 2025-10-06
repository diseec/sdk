#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ STDOUT FUNCTION - Enhanced Logging with Types, Icons, Colors, Levels    ┃
# ┃ Provides a consistent, styled way to log messages with various levels   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Usage: stdout [type] [options] "Your message here"
# Types: -l|--log (default), -d|--debug, -f|--fail, -e|--error, -o|--okey, -w|--warning, -i|--info, -q|--question, -a|--ai, -s|--statement
# Options:
# --processing     (Show processing animation and keep it until next message)
# --icon=ICON   (Custom icon to display instead of default for type)
# --ansi=CODE   (Custom ANSI color code to use instead of default for type)
# --level=LEVEL (Set log level: DEBUG, VERBOSE, INFO, WARNING, ERROR, QUIET)
# Examples:
#   stdout "This is a log message"
#   stdout -i --icon="i" --ansi="34" "This is an info message"
#   stdout --icon="✓" --ansi="32" "This is a success message"
#   stdout -e "This is an error message"
#   stdout -w --icon="!" "This is a warning message"
#   stdout -d --icon="¤" "This is a debug message"
#   stdout -f --icon="✖" "This is a failure message"
#   stdout -q --icon="?" "This is a question message"
#   stdout -a --icon="✦" "This is an AI-related message"
#   stdout -s "This is a plain statement message"
stdout() {
    local repo_name=${D_REPO_NAME:-$D_CLI_GLOBAL_NAME}
    local type="--log"
    local default_level="VERBOSE"
    local default_ansi="90"
    local default_icon=""
    local default_animation="BRAILLE_MIXED"
    local content=""
    local processing=false
    local unique_id="stdout" # Unique identifier for this stdout instance

    # First, check if the first argument is a valid type
    if [ $# -gt 0 ]; then
        case "$1" in
            -l|-d|-f|-e|-o|-w|-i|-q|-a|-s)
                type="$1"
                shift
                ;;
        esac
    fi

    # Now process the rest of the arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --icon=*)
                local given_icon="${1#*=}"
                shift
                ;;
            --ansi=*)
                local given_ansi="${1#*=}"
                shift
                ;;
            --level=*)
                local given_level="${1#*=}"
                shift
                ;;
            --processing)
                processing=true
                shift
                ;;
            *)
                # All remaining arguments form the content
                content="$*"
                break
                ;;
        esac
    done

    # Parse type config
    case $type in
        -l|--log)       default_ansi="90"; default_icon="";  default_level="VERBOSE"; default_animation="BRAILLE_MIXED" ;;
        -d|--debug)     default_ansi="90"; default_icon="";  default_level="DEBUG";   default_animation="BRAILLE_MIXED" ;;
        -f|--fail)      default_ansi="31"; default_icon="✖"; default_level="ERROR";   default_animation="BRAILLE_MIXED" ;; # ✗
        -e|--error)     default_ansi="31"; default_icon="E"; default_level="ERROR";   default_animation="BRAILLE_MIXED" ;;
        -o|--okey)      default_ansi="32"; default_icon="✓"; default_level="INFO";    default_animation="BRAILLE_MIXED" ;; # ✔
        -w|--warning)   default_ansi="33"; default_icon="!"; default_level="WARNING"; default_animation="BRAILLE_MIXED" ;;
        -i|--info)      default_ansi="34"; default_icon="i"; default_level="INFO";    default_animation="BRAILLE_MIXED" ;;
        -q|--question)  default_ansi="35"; default_icon="?"; default_level="ERROR";   default_animation="BRAILLE_MIXED" ;;
        -a|--ai)        default_ansi="96"; default_icon="✦"; default_level="INFO";    default_animation="AI_WRITING"    ;;
        -s|--statement) default_ansi="97"; default_icon="";  default_level="INFO";    default_animation="BRAILLE_MIXED" ;;
        *) stdout -e "No such log type: $type"; return 1 ;;
    esac

    # Prepare icon and ANSI color and level
    local _ansi="${given_ansi:-$default_ansi}"
    local _icon="${given_icon:-$default_icon}"
    local _level="${given_level:-$default_level}"
    local _animation="${given_animation:-$default_animation}"

    # Prepare prompt & content
    local prompt

    if [ "$D_LOG_LEVEL" = "VERBOSE" ] || [ "$D_LOG_LEVEL" = "DEBUG" ]; then    
        prompt="[$(date "+%H:%M:%S")][$(capitalize "$repo_name")]"
        prompt="$(ansi 90 "$prompt")"
    fi

    # Check if icon exists and format accordingly
    if [ -n "$_icon" ]; then
        if is_emoji "$_icon"; then
            # For emojis, don't use brackets
            prompt="$prompt$(ansi $_ansi " $_icon ")"
        else
            # For ASCII symbols, keep the brackets
            prompt="$prompt$(ansi $_ansi "[$_icon]")"
        fi
    fi

    # Only colorize content if it's not empty
    if [ -n "$content" ]; then
        content="$(ansi 90 "$content")"
    fi

    # Handle logging levels
    case $D_LOG_LEVEL in
        DEBUG|debug) ;;
        VERBOSE|verbose) case $_level in DEBUG) return 0; esac ;;
        INFO|info) case $_level in       DEBUG|VERBOSE) return 0; esac ;;
        WARNING|warning) case $_level in VERBOSE|INFO) return 0; esac ;;
        ERROR|error) case $_level in     VERBOSE|INFO|WARNING) return 0; esac ;;
        QUIET|quiet) case $_level in     VERBOSE|INFO|WARNING|ERROR) return 0; esac ;;
    esac

    # Output log message with optional processing animation - send to stderr
    if [ "$processing" = true ]; then
        # First ensure any previous animation is stopped
        processing_stop >&2

        if [ -n "$prompt" ]; then
            printf "%s " "$prompt" >&2
        fi
        
        # Print message without newline - leave space for the animation
        printf "%b\n" "$content" >&2
        
        # Start animation (will auto-stop on next output)
        processing_start "$_animation" >&2
    else
        # Regular output with newline - explicitly stop any running animation first
        processing_stop >&2

        if [ -n "$prompt" ]; then
            printf "%s " "$prompt" >&2
        fi
 
        printf "%b\n" "$content" >&2
    fi
}
