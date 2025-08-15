
#!/bin/bash

# Cache cli path in environment variable
if [ "$PWD" = "$CLI_CACHE_PWD" ] && [ -n "$CLI_CACHE_PATH" ] && [ -f "$CLI_CACHE_PATH/cli" ]; then
    "$CLI_CACHE_PATH/cli" "$@"
    exit $?
fi

dir=$PWD
while :; do
    if [ -f "$dir/cli" ]; then
        export CLI_CACHE_PWD="$PWD"
        export CLI_CACHE_PATH="$dir"
        "$dir/cli" "$@"
        break
    fi
    if [ "$dir" = "/" ]; then
        printf '%s\n' "Error: Could not find an ancestor containing a 'cli', try cd to project root" >&2
        break
    fi
    dir=$(dirname -- "$dir")
done